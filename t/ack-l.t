#!perl

use strict;
use warnings;

use Test::More;

plan tests => 11;

use lib 't';
use Util;

prep_environment();


my @matching = qw(
    t/text/bill-of-rights.txt
    t/text/constitution.txt
);

my @nonmatching = qw(
    t/text/amontillado.txt
    t/text/gettysburg.txt
    t/text/number.txt
    t/text/numbered-text.txt
    t/text/ozymandias.txt
    t/text/raven.txt
);

for my $arg ( qw( -l --files-with-matches ) ) {
    subtest "Files with matches: $arg" => sub {
        my @results = run_ack( $arg, 'strict', 't/text' );
        sets_match( \@results, \@matching, 'File list match' );
    }
}


for my $arg ( qw( -L --files-without-matches ) ) {
    subtest "Files without matches: $arg" => sub {
        my @results = run_ack( $arg, 'strict', 't/text' );
        sets_match( \@results, \@nonmatching, 'File list match' );
    }
}

DASH_L: {
    my @expected = qw(
        t/text/amontillado.txt
        t/text/gettysburg.txt
        t/text/raven.txt
    );

    my @args  = qw( God -i -l --sort-files );
    my @files = qw( t/text );

    ack_sets_match( [ @args, @files ], \@expected, 'Looking for God with -l' );
}

DASH_CAPITAL_L: {
    my @expected = qw(
        t/text/bill-of-rights.txt
        t/text/constitution.txt
        t/text/number.txt
        t/text/numbered-text.txt
        t/text/ozymandias.txt
    );

    my @switches = (
        ['-L'],
        ['--files-without-matches'],
    );

    for my $switches ( @switches ) {
        my @files = qw( t/text );
        my @args  = ( 'God', @{$switches}, '--sort-files' );

        ack_sets_match( [ @args, @files ], \@expected, "Looking for God with @{$switches}" );
    }
}

DASH_LV: {
    my @expected = qw(
        t/text/amontillado.txt
        t/text/bill-of-rights.txt
        t/text/constitution.txt
        t/text/gettysburg.txt
        t/text/number.txt
        t/text/numbered-text.txt
        t/text/ozymandias.txt
        t/text/raven.txt
    );
    my @switches = (
        ['-l','-v'],
        ['-l','--invert-match'],
        ['--files-with-matches','-v'],
        ['--files-with-matches','--invert-match'],
    );

    for my $switches ( @switches ) {
        my @files = qw( t/text );
        my @args  = ( 'religion', @{$switches}, '--sort-files' );

        ack_sets_match( [ @args, @files ], \@expected, '-l -v will match all input files because "religion" will not be on every line' );
    }
}


exit 0;
