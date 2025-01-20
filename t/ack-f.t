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
        ack_sets_match( $test->{args}, $test->{output}, $test->{name} );
        is( get_rc(), $test->{rc} );
    };
}


exit 0;
