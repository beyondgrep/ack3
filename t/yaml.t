#!perl

use warnings;
use strict;

use Test::More tests => 25;

use lib 't';
use Util;

prep_environment();

MAIN: {
    my @yamlfiles = glob( 't/*.yaml' );

    for my $file ( @yamlfiles ) {
        subtest $file => sub () {
            my @tests = read_tests( $file );

            for my $test ( @tests ) {
                my $tempfilename;
                if ( my $stdin = $test->{stdin} ) {
                    my $fh = File::Temp->new( UNLINK => 0 ); # We'll delete it ourselves.
                    $tempfilename = $fh->filename;
                    print {$fh} $stdin;
                    close $fh;
                }

                my @args = (
                    @{$test->{args}},
                    @{$test->{'args-ack3'} // []},
                );
                for my $args ( @args ) {
                    if ( $tempfilename ) {
                        $args = [ @{$args}, $tempfilename ];
                    }
                    subtest $test->{name} . ': ack ' . join( ' ', @{$args} ) => sub {
                        if ( exists $test->{stderr} ) {
                            ack_stderr_matches( $args, $test->{stderr}, $test->{name} );
                            is( get_rc(), $test->{exitcode}, 'Exit code matches' );
                        }
                        else {
                            if ( exists $test->{stdout} ) {
                                my $stdout = $test->{stdout};
                                if ( $test->{ordered} ) {
                                    ack_lists_match( $args, $test->{stdout}, $test->{name} );
                                }
                                else {
                                    ack_sets_match( $args, $test->{stdout}, $test->{name} );
                                }
                                is( get_rc(), $test->{exitcode}, 'Exit code matches' );
                            }
                            else {
                                fail( "stdout must always be specified" );
                            }
                        }
                    }
                }
                if ( $tempfilename ) {
                    unlink( $tempfilename );
                }
            }
        };
    }
}


exit 0;
