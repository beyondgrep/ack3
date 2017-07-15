#!perl -T

use strict;
use warnings;
use lib 't';
use Test::More tests => 2;
use Util;

prep_environment();

subtest 'Lua shebang' => sub {
    plan tests => 1;

    ack_sets_match(
        [ '--lua', '-f', 't/swamp' ],
        [ 't/swamp/lua-shebang-test' ],
        'Lua files should be detected by shebang'
    );
};


subtest 'R extensions' => sub {
    plan tests => 2;

    my @expected = qw(
        t/swamp/example.R
    );

    my @args    = qw( --rr -f );
    my @results = run_ack( @args );

    sets_match( \@results, \@expected, __FILE__ );
};

done_testing();
exit 0;
