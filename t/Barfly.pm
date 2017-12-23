package Barfly;

use warnings;
use strict;

use Test::More;

sub run_tests {
    my $class    = shift;
    my $filename = shift;

    my $self = bless {
        blocks => [],
    }, $class;

    my $block;
    my $section;

    open( my $fh, '<', $filename ) or die "Can't open $filename: $!";

    my %blocknames_seen;
    my $lineno = 0;
    while ( my $line = <$fh> ) {
        ++$lineno;
        chomp $line;
        $line =~ s/\s*$//;
        next if $line =~ /^#/;
        next unless $line =~ /\S/;

        $line =~ s/\s+$//;
        if ( $line =~ /^BEGIN\s+(.*)/ ) {
            if ( defined($block) ) {
                die 'We are already in the middle of a block';
            }

            my $blockname = $1;
            $blocknames_seen{ $blockname }++ and die qq{Block "$blockname" is duplicated in $filename at $lineno};

            $block = Barfly::Block->new( $blockname, $filename, $lineno );
            $section = undef;
        }
        elsif ( $line eq 'END' ) {
            push( @{$self->{blocks}}, $block );
            $block = undef;
            $section = undef;
        }
        elsif ( $line eq 'RUN' || $line eq 'YES' || $line eq 'NO' || $line eq 'YESLINES' ) {
            $section = $line;
        }
        else {
            $block->add_line( $section, $line );
        }
    }
    close $fh or die "Can't close $filename: $!";

    my @blocks = @{$self->{blocks}} or return fail( "No blocks found in $filename!" );
    for my $block ( @blocks ) {
        $block->run;
    }

    return;
}


package Barfly::Block;

use Test::More;
use Util;

sub new {
    my $class    = shift;
    my $label    = shift // die 'Block label cannot be blank';
    my $filename = shift;
    my $lineno   = shift;

    return bless {
        label    => $label,
        filename => $filename,
        lineno   => $lineno,
    }, $class;
}

sub add_line {
    my $self    = shift;
    my $section = shift;
    my $line    = shift;

    push @{$self->{$section}}, $line;

    return;
}


sub run {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $self = shift;

    return subtest sprintf( '%s: %s, line %d', $self->{label}, $self->{filename}, $self->{lineno} ) => sub {
        plan tests => 2;

        my @command_lines = @{$self->{RUN} // []} or die 'No RUN lines specified!';

        subtest "$self->{label}: YES/NO" => sub {
            plan tests => scalar @command_lines;

            # Set up scratch file
            my @yes = @{$self->{YES} // []};
            my @no  = @{$self->{NO} // []};

            my $tempfile = create_tempfile( @yes, @no );

            for my $command_line ( @command_lines ) {
                subtest $command_line => sub {
                    plan tests => 2;

                    $command_line = _untaint( $command_line );

                    my @args = split( / /, $command_line );
                    @args > 1 or die "Invalid command line: $command_line";
                    shift @args eq 'ack' or die 'Command line must begin with ack';

                    my @results = main::run_ack( @args, $tempfile->filename );
                    main::lists_match( \@results, \@yes, $command_line );
                };
            }
        };

        subtest "$self->{label}: YESLINES" => sub {
            return pass( 'No yeslines' ) if !$self->{YESLINES};

            plan tests => scalar @command_lines;

            my @all_lines   = @{$self->{YESLINES}};
            my @input_lines = grep { /[^ ^]/ } @all_lines;
            my $tempfile    = create_tempfile( @input_lines );

            for my $command_line ( @command_lines ) {
                subtest $command_line => sub {
                    plan tests => 2;

                    $command_line = _untaint( $command_line );

                    my @args = split( / /, $command_line );
                    @args > 1 or die "Invalid command line: $command_line";
                    shift @args eq 'ack' or die 'Command line must begin with ack';

                    push( @args, '--underline' );

                    my @results = main::run_ack( @args, $tempfile->filename );
                    main::lists_match( \@results, \@all_lines, $command_line );
                };
            }
        };
    };
}

sub _untaint {
    return $_[0] =~ /(.*)/ ? $1 : undef;
}

1;
