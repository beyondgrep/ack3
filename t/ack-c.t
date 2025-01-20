#!perl

use warnings;
use strict;

use Test::More tests => 7;

use lib 't';
use Util;

prep_environment();

my @tests = read_tests( 't/ack-c.yaml' );

for my $test ( @tests ) {
    subtest $test->{name} => sub () {
        for my $args ( @{$test->{args}} ) {
            ack_sets_match( $args, $test->{output}, $test->{name} );
            is( get_rc(), $test->{rc} );
        }
    };
}

exit 0;
