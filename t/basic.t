#!perl

use strict;
use warnings;
use lib 't';

use Util;
use Test::More tests => 5;

prep_environment();


my @tests = read_tests( 't/basic.yaml' );

for my $test ( @tests ) {
    subtest $test->{name} => sub () {
        for my $args ( @{$test->{args}} ) {
            my @results = run_ack( @{$args} );
            lists_match( \@results, $test->{output}, $test->{name} );
        }
    };
}


exit 0;
