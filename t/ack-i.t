#!perl

use strict;
use warnings;
use lib 't';

use Test::More tests => 9;

use Util;
use Barfly;

prep_environment();

Barfly->run_tests( 't/ack-i.barfly' );

subtest 'Straight -i' => sub {
    plan tests => 4;

    my @expected = (
        't/swamp/groceries/fruit:1:apple',
        't/swamp/groceries/junk:1:apple fritters',
    );

    my @targets = map { "t/swamp/groceries/$_" } qw( fruit junk meat );

    my @args    = qw( --nocolor APPLE -i );
    my @results = run_ack( @args, @targets );

    lists_match( \@results, \@expected, '-i flag' );

    @args    = qw( --nocolor APPLE --ignore-case );
    @results = run_ack( @args, @targets );

    lists_match( \@results, \@expected, '--ignore-case flag' );
};

done_testing();

exit 0;
