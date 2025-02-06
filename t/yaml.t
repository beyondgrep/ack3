#!perl

use warnings;
use strict;

use Test::More tests => 12;

use lib 't';
use Util;

prep_environment();

MAIN: {
    my @yamlfiles = glob( 't/*.yaml' );

    for my $file ( @yamlfiles ) {
        subtest $file => sub () {
            my @tests = read_tests( $file );

            for my $test ( @tests ) {
                for my $args ( @{$test->{args}} ) {
                    subtest $file . ' ' . join( ', ', @{$args} ) => sub {
                        if ( $test->{ordered} ) {
                            ack_lists_match( $args, $test->{stdout}, $test->{name} );
                        }
                        else {
                            ack_sets_match( $args, $test->{stdout}, $test->{name} );
                        }
                        is( get_rc(), $test->{exitcode} );
                    }
                }
            }
        };
    }
}


exit 0;
