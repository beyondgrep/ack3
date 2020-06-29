#!perl

use warnings;
use strict;

use Test::More;

use lib 't';
use Util;

plan tests => 15;

prep_environment();

my $match               = "\e[30;43m";
my $green_bold          = "\e[1;32m";
my $yellow_bold         = "\e[1;33m";
my $red                 = "\e[31m";
my $cyan                = "\e[36m";
my $cyan_on_red         = "\e[36;41m";
my $bold_white_on_green = "\e[1;37;42m";
my $blue_bold           = "\e[1;34m";

my $color_end = "\e[0m";
my $line_end  = "\e[0m\e[K";

NORMAL_COLOR: {
    my @files = qw( t/text/bill-of-rights.txt );
    my @args = qw( free --color );
    my @results = run_ack( @args, @files );

    ok( grep { /\e/ } @results, 'normal match highlighted' ) or diag(explain(\@results));
}

MATCH_WITH_BACKREF: {
    my @files = qw( t/text/bill-of-rights.txt );
    my @args = qw( (free).*\1 --color );
    my @results = run_ack( @args, @files );

    is( @results, 1, 'backref pattern matches once' );

    ok( grep { /\e/ } @results, 'match with backreference highlighted' );
}

BRITISH_COLOR: {
    my @files = qw( t/text/bill-of-rights.txt );
    my @args = qw( free --colour );
    my @results = run_ack( @args, @files );

    ok( grep { /\e/ } @results, 'normal match highlighted' );
}

MULTIPLE_MATCHES: {
    my @files = qw( t/text/amontillado.txt );
    my @args = qw( az.+?e|ser.+?nt -w --color );
    my @results = run_ack( @args, @files );

    is_deeply( \@results, [
        "\"A huge human foot d'or, in a field ${match}azure${color_end}; the foot crushes a ${match}serpent${color_end}$line_end",
    ] );
}


ADJACENT_CAPTURE_COLORING: {
    my @files = qw( t/text/raven.txt );
    my @args = qw( (Temp)(ter) --color );
    my @results = run_ack( @args, @files );

    is_deeply( \@results, [
        "Whether ${match}Tempter${color_end} sent, or whether tempest tossed thee here ashore,$line_end",
    ] );
}


subtest 'Heading colors, single line' => sub {
    plan tests => 4;

    # Without the column number
    my $file = reslash( 't/text/ozymandias.txt' );
    my @args = qw( mighty -i -w --color -H );
    my @results = run_ack( @args, $file );

    is_deeply( \@results, [
        "${green_bold}$file${color_end}:${yellow_bold}11${color_end}:Look on my works, ye ${match}Mighty${color_end}, and despair!'$line_end",
    ] );

    # With column number
    @results = run_ack( @args, '--column', $file );
    is_deeply( \@results, [
        "${green_bold}$file${color_end}:${yellow_bold}11${color_end}:${yellow_bold}22${color_end}:Look on my works, ye ${match}Mighty${color_end}, and despair!'$line_end",
    ] );
};


subtest 'Heading colors, grouped' => sub {
    plan tests => 4;

    # Without the column number
    my $file = reslash( 't/text/ozymandias.txt' );
    my @args = qw( mighty -i -w --color --group );
    my @results = run_ack( @args, 't/text' );

    is_deeply( \@results, [
        "${green_bold}$file${color_end}",
        "${yellow_bold}11${color_end}:Look on my works, ye ${match}Mighty${color_end}, and despair!'$line_end",
    ] );

    # With column number
    @results = run_ack( @args, '--column', 't/text' );
    is_deeply( \@results, [
        "${green_bold}$file${color_end}",
        "${yellow_bold}11${color_end}:${yellow_bold}22${color_end}:Look on my works, ye ${match}Mighty${color_end}, and despair!'$line_end",
    ] );
};


subtest 'Passing args for colors' => sub {
    plan tests => 2;

    # Without the column number
    my $file = reslash( 't/text/ozymandias.txt' );
    my @args = ( qw( mighty -i -w --color --group --column ),
        '--color-match=cyan on_red',
        '--color-filename=red',
        '--color-lineno=bold white on_green',
        '--color-colno=bold blue',
    );
    my @results = run_ack( @args, 't/text' );

    is_deeply( \@results, [
        "${red}$file${color_end}",
        "${bold_white_on_green}11${color_end}:${blue_bold}22${color_end}:Look on my works, ye ${cyan_on_red}Mighty${color_end}, and despair!'$line_end",
    ] );
};

subtest 'Filename colors with count' => sub {
    plan tests => 2;

    my $file = reslash( 't/text/bill-of-rights.txt' );
    my $expected = "${red}$file${color_end}:1";
    my @args = qw(
        Congress
        --count
        --with-filename
        --color
        --color-filename=red
    );

    my @results = run_ack( @args, $file );
    is_deeply( \@results, [ $expected ], "Filename colored when called with '--color'" );
};


done_testing();

exit 0;
