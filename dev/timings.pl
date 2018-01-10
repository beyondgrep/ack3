#!/usr/bin/env perl

use strict;
use warnings;
use autodie;
use 5.10.1;

use Getopt::Long;
use File::Slurp qw(read_dir read_file write_file);
use File::Spec;
use JSON;
use List::MoreUtils qw(any);
use Term::ANSIColor qw(colored);
use Time::HiRes qw(gettimeofday tv_interval);

my $show_colors;
my $perform_store;
my $perfom_clear;
my $num_iterations = 1;
my $set = 'all';

my @use_acks;
my $perl = $^X;

my %sets = (
    all => [
        [ 'foo' ],
        [ 'foo', '-w' ],
        [ 'foo.', '-w' ],
        [ '-f' ],
        [ 'foo', '-l' ],
        [ 'foo', '-A10' ],
        [ 'foo', '-B10' ],
        [ 'foo', '-C10' ],
    ],
    context => [
        [ 'foo' ],
        [ 'foo', '-A10' ],
        [ 'foo', '-B10' ],
        [ 'foo', '-C10' ],
    ],
    speed => [
        [ 'foo' ],
        [ 'foo', '-w' ],
        [ 'foo.', '-w' ],
        [ 'foo\w+' ],
    ],
);


GetOptions(
    'clear'   => \$perfom_clear,
    'store'   => \$perform_store,
    'color'   => \$show_colors,
    'times=i' => \$num_iterations,
    'ack=s@'  => \@use_acks,
    'perl=s'  => \$perl,
    'set=s'   => \$set,
);

my $SOURCE_DIR = shift or die "Must specify a path";

my $invocations = $sets{$set} or die "Unknown set $set: Must be one of: ", join( ', ', sort keys %sets ), "\n";
my @invocations = @{$invocations};
push( @{$_}, $SOURCE_DIR ) for @invocations;

if ($perfom_clear) {
    unlink('.timings.json');
}

my $json = JSON->new->utf8->pretty;
my $previous_timings;
if ( -e '.timings.json' ) {
    $previous_timings = $json->decode(scalar(read_file('.timings.json')));
}

my @acks = map { File::Spec->catfile('garage', $_) } read_dir('garage');
push @acks, 'ack-standalone';

@acks = grab_versions(@acks);

# Test ag and ripgrep if we have them.
for my $ackalike ( qw( ag rg ) ) {
    for my $dir ( qw( /usr/bin /usr/local/bin ) ) {
        my $path = "$dir/$ackalike";
        if ( -x $path ) {
            push( @acks, { path => $path, version => $ackalike } );
        }
    }
}
if ( @use_acks ) {
    foreach my $ack (@acks) {
        next if $ack->{'version'} eq 'HEAD';
        next if $ack->{'version'} eq 'previous';
        unless(any { $_ eq $ack->{'version'} } @use_acks) {
            undef $ack;
        }
    }
    @acks = grep { defined } @acks;
}
@acks = sort {
    my ($na,$nb) = map { $_ eq 'HEAD' ? 99 : $_ } ( $a->{'version'}, $b->{'version'} );
    return $na cmp $nb;
} @acks;

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

    foreach my $ack (@acks) {
        my $elapsed;

        if ($ack->{'path'}) {
            $elapsed = time_ack($ack, $invocation, $perl);
        }
        else {
            $elapsed = $previous_timings->{join(' ', 'ack', @$invocation)};
        }
        if (defined $elapsed) {
            $elapsed = sprintf('%.2f', $elapsed);
        }
        push @timings, color($previous_timing, $elapsed);
        $previous_timing = $elapsed if defined $elapsed;

        if ($perform_store && $ack->{'store_timings'}) {
            $stored_timings{join(' ', 'ack', @$invocation)} = $elapsed;
        }
    }
    printf $format, join(' ', 'ack', @$invocation), map { $_ // color('x_x') } @timings;

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
            if($output =~ /ack\s+(?<version>\d+[.]\d+(_\d+)?)/) {
                $version = $+{'version'};
            }
            else {
                # XXX uh-oh
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

    my $max_invocation_length = -1;

    foreach my $invocation (@$invocations) {
        my $length = length(join(' ', 'ack', @$invocation));
        if($length > $max_invocation_length) {
            $max_invocation_length = $length;
        }
    }

    my @max_version_lengths = (length(color('000.00'))) x @$acks;

    for(0..$#$acks) {
        if(length($acks->[$_]{'version'}) > $max_version_lengths[$_]) {
            $max_version_lengths[$_] = length($acks->[$_]{'version'});
        }
    }

    return join(' | ', "%${max_invocation_length}s", map {
        "%${_}s"
    } @max_version_lengths) . "\n";
}

sub time_ack {
    my ( $ack, $invocation, $perl ) = @_;

    my @args = ( $ack->{'path'}, @$invocation );

    # Only ack has --noenv and is run under Perl.
    if ( $ack->{'path'} =~ /ack/ ) {
        @args = ( $perl, @args, '--noenv' );
    }

    if ( $ack->{'path'} =~ /ack-1/ ) {
        @args = grep { !/--known/ } @args;
    }

    my $end;
    my $start = [gettimeofday()];
    for ( 1 .. $num_iterations ) {
        my ( $read, $write );
        pipe $read, $write;
        my $pid   = fork;

        my $has_error_lines;

        if($pid) {
            close $write;
            while(<$read>) {
                $has_error_lines = 1;
            }
            waitpid $pid, 0;
            return if $has_error_lines;
        }
        else {
            close $read;
            open STDOUT, '>', File::Spec->devnull;
            open STDERR, '>&', $write;
            exec @args;
            exit 255;
        }
    }
    $end = [gettimeofday()];

    return tv_interval($start, $end) / $num_iterations;
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

__DATA__

TODO:

  * Percentage slowdown per invocation
  * Overall stats dump at the end.
  * Stop passing bad options to 1.x (--known)
