#!perl

use warnings;
use strict;

use Test::More tests => 20;

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
                for my $args ( @{$test->{args}} ) {
                    if ( $tempfilename ) {
                        $args = [ @{$args}, $tempfilename ];
                    }
                    subtest $test->{name} . ' ' . join( ', ', @{$args} ) => sub {
                        if ( $test->{ordered} ) {
                            ack_lists_match( $args, $test->{stdout}, $test->{name} );
                        }
                        else {
                            ack_sets_match( $args, $test->{stdout}, $test->{name} );
                        }
                        is( get_rc(), $test->{exitcode} );
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
