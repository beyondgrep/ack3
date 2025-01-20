#!perl

use warnings;
use strict;

use Test::More tests => 3;

use lib 't';
use Util;

prep_environment();

my @tests = read_tests( 't/ack-f.yaml' );

for my $test ( @tests ) {
    subtest $test->{name} => sub () {
        for my $args ( @{$test->{args}} ) {
            ack_sets_match( $args, $test->{stdout}, $test->{name} );
            is( get_rc(), $test->{exitcode} );
        }
    };
}


exit 0;
