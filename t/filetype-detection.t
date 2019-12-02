#!perl

use strict;
use warnings;

use Test::More tests => 3;

use lib 't';
use Util;

prep_environment();

subtest 'Lua shebang' => sub {
    plan tests => 1;

    ack_sets_match(
        [qw( -t lua -f t/swamp )],
        [ 't/swamp/lua-shebang-test' ],
        'Lua files should be detected by shebang'
    );
};


subtest 'R extensions' => sub {
    plan tests => 2;

    my @expected = qw(
        t/swamp/example.R
    );

    my @args    = qw( -t rr -f );
    my @results = run_ack( @args );

    sets_match( \@results, \@expected, __FILE__ );
};


subtest 'ASP.NET' => sub {
    my @expected = qw(
        t/swamp/MasterPage.master
        t/swamp/Sample.ascx
        t/swamp/Sample.asmx
        t/swamp/sample.aspx
        t/swamp/service.svc
    );

    my @args    = qw( -t aspx -f );
    my @results = run_ack(@args);

    sets_match( \@results, \@expected, __FILE__ );
};

done_testing();
exit 0;
