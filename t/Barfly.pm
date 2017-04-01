package Barfly;

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

    while ( my $line = <$fh> ) {
        chomp $line;
        next if $line =~ /^#/;
        next unless $line =~ /\S/;

        $line =~ s/\s+$//;
        if ( $line =~ /^BEGIN\s*(.*)/ ) {
            !defined($block) or die 'We are already in the middle of a block';

            $block = Barfly::Block->new( $1 );
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
    my $class = shift;
    my $label = shift // die 'Block label cannot be blank';

    return bless {
        label => $label,
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

    return subtest $self->{label} => sub {
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

                    $command_line =~ /(.*)/;
                    $command_line = $1;

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

                    $command_line =~ /(.*)/;
                    $command_line = $1;

                    my @args = split( / /, $command_line );
                    @args > 1 or die "Invalid command line: $command_line";
                    shift @args eq 'ack' or die 'Command line must begin with ack';

                    push( @args, '--underline' );

                    my @results = main::run_ack( @args, $tempfile->filename );
                    main::lists_match( \@results, \@all_lines, $command_line );
                };
            }
        }
    };
}

1;
