#!/usr/bin/env perl

use strict;
use warnings;
use autodie;
use 5.10.1;

use lib 't';
use Util qw( read_file write_file );

use File::Next;
use File::Spec;
use Getopt::Long;
use JSON;
use List::Util qw( any max );
use Term::ANSIColor qw(colored);
use Time::HiRes qw(gettimeofday tv_interval);

my $show_colors;
my $perform_store;
my $perform_clear;
my $test_others;
my $num_iterations = 1;
my $set = 'searching';

my @use_acks;
my @use_acks_matches;
my $perl = $^X;

my %sets = (
    searching => [
        [ 'xxx-no-match' ],
        [ 'foo' ],
        [ 'foo', '-w' ],
        [ 'foo', '-w', '-i' ],
        [ 'foo\w+', '-w' ],
        [ 'foo\w+', '-w', '-i' ],
        [ '\w+der', '-w' ],
        [ '\w+der', '-w', '-i' ],
        [ 'foo\w+', '-C10' ],
        [ 'foo\w+', '-C10', '-i' ],
        [ '\w+der', '-C10' ],
        [ '\w+der', '-C10', '-i' ],
        [ '(set|get)_\w+' ],
        [ '(set|get)_\w+', '-i' ],
    ],
    case => [
        [ 'foo' ],
        [ '[Ff][Oo][Oo]' ],
        [ 'foo', '-i' ],

        [ 'foo\w+' ],
        [ '[Ff][Oo][Oo]\w+' ],
        [ 'foo\w+', '-i' ],

        [ '(set|get)_\w+' ],
        [ '([Ss][Ee][Tt]|[Gg][Ee][Tt])_\w+' ],
        [ '(set|get)_\w+', '-i' ],
    ],
    range => [
        [ 'foo' ],
        [ 'foo', '--range-start=^sub' ],
        [ 'foo', '--range-end=^}' ],
        [ 'foo', '--range-start=^sub', '--range-end=^}' ],
        [ 'foo', '-l' ],
        [ 'foo', '-l', '--range-start=^sub' ],
        [ 'foo', '-l', '--range-end=^}' ],
        [ 'foo', '-l', '--range-start=^sub', '--range-end=^}' ],
    ],
    context => [
        [ 'foo' ],
        [ 'foo', '-A10' ],
        [ 'foo', '-B10' ],
        [ 'foo', '-C10' ],
    ],
    files => [
        [ '-f' ],
        [ '-g', 'hash' ],
        [ 'foo', '-l' ],
        [ 'foo', '-c' ],
        [ 'foo', '-L' ],
        [ 'foo$', '-l' ],
        [ 'foo$', '-c' ],
        [ 'foo$', '-L' ],
        [ 'foo\w+', '-l' ],
        [ 'foo\w+', '-c' ],
        [ 'foo\w+', '-L' ],
        [ 'foo\w+', '-w', '-l' ],
        [ 'foo\w+', '-w', '-c' ],
        [ 'foo\w+', '-w', '-L' ],
    ],
    slow => [
        [ '\w+date', '-w' ],
        [ '\w+date', '-w', '-i' ],
    ],
    types => [
        [ 'foo' ],
        [ 'foo', '--type=perl' ],
        [ 'foo', '--type=noperl' ],
        [ 'foo', '--type=python' ],
        [ 'foo', '--type=nopython' ],
        [ 'foo', '--type=ocaml' ],
        [ 'foo', '--type=noocaml' ],
    ],
);


GetOptions(
    'clear'        => \$perform_clear,
    'store'        => \$perform_store,
    'color'        => \$show_colors,
    'others'       => \$test_others,
    'times=i'      => \$num_iterations,
    'ack=s@'       => \@use_acks,
    'ack-match=s@' => \@use_acks_matches,
    'perl=s'       => \$perl,
    'set=s'        => \$set,
    'head'         => sub { @use_acks = ('HEAD') },
) or die;

my $SOURCE_DIR = shift or die "Must specify a path\n";

my $invocations = $sets{$set} or die "Unknown set $set: Must be one of: ", join( ', ', sort keys %sets ), "\n";
my @invocations = @{$invocations};
push( @{$_}, $SOURCE_DIR ) for @invocations;

if ($perform_clear) {
    unlink('.timings.json');
}

my $json = JSON->new->utf8->pretty;
my $previous_timings;
if ( -e '.timings.json' ) {
    $previous_timings = $json->decode(scalar(read_file('.timings.json')));
}

my @acks = ( 'ack-standalone' );
my $iter = File::Next::files( 'garage' );
while ( my $file = $iter->() ) {
    push( @acks, $file );
}

@acks = grab_versions(@acks);

if ( @use_acks || @use_acks_matches ) {
    foreach my $ack (@acks) {
        my $keep;

        $keep ||= $ack->{'version'} eq 'HEAD';
        $keep ||= $ack->{'version'} eq 'previous';

        $keep ||= any { $ack->{'version'} eq $_ } @use_acks;
        $keep ||= any { $ack->{'version'} =~ /$_/ } @use_acks_matches;

        undef $ack unless $keep;
    }
    @acks = grep { defined } @acks;
}
@acks = sort {
    my ($na,$nb) = map { $_ eq 'HEAD' ? 99 : $_ } ( $a->{'version'}, $b->{'version'} );
    return $na cmp $nb;
} @acks;

# Test grep, ag and ripgrep if we have them.
if ( $test_others ) {
    for my $ackalike ( qw( grep egrep ag rg ) ) {
        for my $dir ( qw( /usr/bin /usr/local/bin ) ) {
            my $path = "$dir/$ackalike";
            if ( -x $path ) {
                my $parms = { path => $path, version => $ackalike };
                if ( $ackalike =~ /grep/ ) {
                    $parms->{extra_args} = [ '-R' ];
                }
                push( @acks, $parms );
            }
        }
    }
}

if ($previous_timings) {
    splice @acks, -1, 0, {
        version => 'previous',
    };
}

say "Testing under Perl $], $^X";
say '';
my $format = create_format(\@invocations, \@acks, $show_colors);
my $header = sprintf $format, '', map { color($_->{'version'})  } @acks;
print $header;
my $dashes = '-' x (length($header) - 1); # -1 for the newline
say $dashes;

my %stored_timings;

my @total_timings;
foreach my $invocation (@invocations) {
    my @timings;

    my $previous_timing;

    my @line_counts;
    foreach my $ack (@acks) {
        my $elapsed;
        my $nlines;

        if ($ack->{'path'}) {
            ($elapsed,$nlines) = time_ack($ack, $invocation, $perl);
        }
        else {
            $elapsed = $previous_timings->{join(' ', 'ack', @$invocation)};
        }
        if (defined $elapsed) {
            $elapsed = sprintf('%.2f', $elapsed);
        }
        push @timings, color($previous_timing, $elapsed);
        $previous_timing = $elapsed if defined $elapsed;
        push( @line_counts, $nlines );

        if ($perform_store && $ack->{'store_timings'}) {
            $stored_timings{join(' ', 'ack', @$invocation)} = $elapsed;
        }
    }

    printf $format, display_invocation( $invocation ), map { $_ // color('x_x') } @timings;
    if ( 0 && !counts_valid( @line_counts ) ) {
        say 'Line counts not valid: ' . join( ', ', map { $_ // 'undef' } @line_counts );
    }

    my $i = 0;
    $total_timings[$i++] += ($_//0) for @timings;
}
say $dashes;
printf $format, 'Total', map { sprintf( '%.2f', $_ ) } @total_timings;

if ($perform_store) {
    write_file('.timings.json', $json->encode(\%stored_timings));
}

exit 0;

sub grab_versions {
    my @acks = @_;

    my @annotated_acks;

    foreach my $ack (@acks) {
        my $version;

        if($ack =~ /standalone/) {
            $version = 'HEAD';
        }
        else {
            my $output = `$^X $ack --noenv --version 2>&1`;
            if ( $output =~ /ack\s+(?<version>\d+[.]\d+(_\d+)?)/ ) {
                $version = $+{'version'};
            }
            elsif ( $output =~ /ack\s+v(?<version>\d+[.]\d+[.]\d+)/ ) {
                $version = $+{'version'};
            }
            else {
                die "UNABLE TO PARSE $output";
            }
        }

        push @annotated_acks, {
            path    => $ack,
            version => $version,
        };

        if($version eq 'HEAD') {
            $annotated_acks[-1]{'store_timings'} = 1;
        }
    }

    return @annotated_acks;
}

sub create_format {
    my ( $invocations, $acks, $show_colors ) = @_;

    my $max_invocation_length = max map { length display_invocation($_) } @{$invocations};

    my @max_version_lengths = (length(color('000.00'))) x @$acks;

    for(0..$#$acks) {
        if(length($acks->[$_]{'version'}) > $max_version_lengths[$_]) {
            $max_version_lengths[$_] = length($acks->[$_]{'version'});
        }
    }

    return join(' :', "%-${max_invocation_length}.${max_invocation_length}s", map {
        "%${_}s"
    } @max_version_lengths) . "\n";
}

sub time_ack {
    my ( $ack, $invocation, $perl ) = @_;

    my @args = ( $ack->{'path'}, @{$invocation} );
    push( @args, @{$ack->{extra_args}} ) if $ack->{extra_args};

    # Only ack has --noenv and is run under Perl.
    if ( $ack->{'path'} =~ /ack/ ) {
        @args = ( $perl, @args, '--noenv' );
    }

    if ( $ack->{'path'} =~ /ack-1/ ) {
        @args = grep { !/--known/ } @args;
    }

    my $end;
    my $start = [gettimeofday()];

    # We use the last invocations
    my $n_errlines;
    my $n_stdoutlines;

    for ( 1 .. $num_iterations ) {
        my ( $read, $write );
        pipe $read, $write;

        my ( $r_stdout, $w_stdout );
        pipe $r_stdout, $w_stdout;

        $n_stdoutlines = 0;
        $n_errlines = 0;

        my $pid   = fork;

        if($pid) {
            close $write;
            close $w_stdout;
            while (<$r_stdout>) {
                ++$n_stdoutlines;
            }
            while(<$read>) {
                ++$n_errlines;
            }
            waitpid $pid, 0;
            return if $n_errlines;
        }
        else {
            close $read;
            close $r_stdout;
            open STDOUT, '>&', $w_stdout;
            open STDERR, '>&', $write;
            exec @args;
            exit 255;
        }
    }
    $end = [gettimeofday()];

    my $time = tv_interval($start, $end) / $num_iterations;

    return ( $time, $n_stdoutlines, $n_errlines );
}

sub color {
    my ( $previous_value, $value );

    if ( @_ == 2 ) {
        ( $previous_value, $value ) = @_;
    }
    else {
        ( $value ) = @_;
    }

    return $value if !$show_colors;
    return $value if !defined($value);

    return colored(['white'], $value) if !defined($previous_value);

    if ( $previous_value < $value ) {
        return colored(['red'], $value);
    }
    else {
        return colored(['green'], $value);
    }
}

sub counts_valid {
    my @counts;
    my %counts;

    ++$counts{$_//'undef'} for @_;

    return (@counts>0) && ($counts[0]>0) && (keys %counts == 1);
}


sub display_invocation {
    my $invocation = shift;

    my @args = @{$invocation};
    pop @args;  # Don't show the directory.

    return join( ' ', 'ack', @args );
}

__DATA__

TODO:

  * Percentage slowdown per invocation
  * Overall stats dump at the end.
  * Stop passing bad options to 1.x (--known)
