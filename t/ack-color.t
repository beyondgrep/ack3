#!perl -T

use warnings;
use strict;

use Test::More;

use lib 't';
use Util;

plan tests => 12;

prep_environment();

my $match_start  = "\e[30;43m";
my $match_end    = "\e[0m";
my $line_end     = "\e[0m\e[K";

my $green_start  = "\e[1;32m";
my $green_end    = "\e[0m";

my $yellow_start = "\e[1;33m";
my $yellow_end   = "\e[0m";

NORMAL_COLOR: {
    my @files = qw( t/text/boy-named-sue.txt );
    my @args = qw( called --color );
    my @results = run_ack( @args, @files );

    ok( grep { /\e/ } @results, 'normal match highlighted' ) or diag(explain(\@results));
}

MATCH_WITH_BACKREF: {
    my @files = qw( t/text/boy-named-sue.txt );
    my @args = qw( (called).*\1 --color );
    my @results = run_ack( @args, @files );

    is( @results, 1, 'backref pattern matches once' );

    ok( grep { /\e/ } @results, 'match with backreference highlighted' );
}

BRITISH_COLOR: {
    my @files = qw( t/text/boy-named-sue.txt );
    my @args = qw( called --colour );
    my @results = run_ack( @args, @files );

    ok( grep { /\e/ } @results, 'normal match highlighted' );
}

MULTIPLE_MATCHES: {
    my @files = qw( t/text/freedom-of-choice.txt );
    my @args = qw( v.+?m|c.+?n -w --color );
    my @results = run_ack( @args, @files );

    is( @results, 1, 'multiple matches on 1 line' );
    is( $results[0], "A ${match_start}victim${match_end} of ${match_start}collision${match_end} on the open sea$line_end",
        'multiple matches highlighted' );
}


subtest 'Heading colors, single line' => sub {
    plan tests => 6;

    # Without the column number
    my $file = reslash( 't/text/science-of-myth.txt' );
    my @args = qw( mutually -w --color -H );
    my @results = run_ack( @args, $file );

    is( $results[0], "${green_start}$file${green_end}:${yellow_start}13${yellow_end}:Science and religion are not ${match_start}mutually${match_end} exclusive$line_end", 'Properly row highlights' );
    is( scalar @results, 1, 'Only one line back' );

    # With column number
    @results = run_ack( @args, '--column', $file );
    is( $results[0], "${green_start}$file${green_end}:${yellow_start}13${yellow_end}:${yellow_start}30${yellow_end}:Science and religion are not ${match_start}mutually${match_end} exclusive$line_end", 'Properly row highlights' );
    is( scalar @results, 1, 'Only one line back' );
};


subtest 'Heading colors, grouped' => sub {
    plan tests => 8;

    # Without the column number
    my $file = reslash( 't/text/science-of-myth.txt' );
    my @args = qw( mutually -w --color --group );
    my @results = run_ack( @args, 't/text' );

    is( $results[0], "${green_start}$file${green_end}", 'Heading is right' );
    is( $results[1], "${yellow_start}13${yellow_end}:Science and religion are not ${match_start}mutually${match_end} exclusive$line_end", 'Match line OK' );
    is( scalar @results, 2, 'Exactly two lines' );

    # With column number
    @results = run_ack( @args, '--column', 't/text' );
    is( $results[0], "${green_start}$file${green_end}", 'Heading is right' );
    is( $results[1], "${yellow_start}13${yellow_end}:${yellow_start}30${yellow_end}:Science and religion are not ${match_start}mutually${match_end} exclusive$line_end", 'Match line OK' );
    is( scalar @results, 2, 'Exactly two lines' );
};

done_testing();

exit 0;
