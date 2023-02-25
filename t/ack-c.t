#!perl

use warnings;
use strict;

use Test::More tests => 7;

use lib 't';
use Util;

prep_environment();

DASH_C: {
    my @expected = qw(
        t/text/amontillado.txt:2
        t/text/bill-of-rights.txt:0
        t/text/constitution.txt:0
        t/text/gettysburg.txt:1
        t/text/number.txt:0
        t/text/numbered-text.txt:0
        t/text/ozymandias.txt:0
        t/text/raven.txt:2
    );

    my @args  = qw( God -c --sort-files );
    my @files = qw( t/text );

    ack_sets_match( [ @args, @files ], \@expected, 'God counts' );

    push( @args, '--no-filename' );
    ack_sets_match( [ @args, @files ], [ 5 ], 'God counts, total only' );
}


WITH_DASH_V: {
    my @expected = qw(
        t/text/amontillado.txt:206
        t/text/bill-of-rights.txt:45
        t/text/constitution.txt:259
        t/text/gettysburg.txt:15
        t/text/number.txt:1
        t/text/numbered-text.txt:20
        t/text/ozymandias.txt:9
        t/text/raven.txt:77
    );

    my @args  = qw( the -i -w -v -c --sort-files );
    my @files = qw( t/text );

    ack_sets_match( [ @args, @files ], \@expected, 'Non-the counts' );
}


DASH_LC: {
    my @expected = qw(
        t/text/bill-of-rights.txt:1
        t/text/constitution.txt:29
    );

    my @args  = qw( congress -i -l -c --sort-files );
    my @files = qw( t/text );

    ack_sets_match( [ @args, @files ], \@expected, 'congress counts with -l -c' );
}


DASH_HC: {
    my @args     = qw( Montresor -c -h );
    my @files    = qw( t/text );
    my @expected = ( '3' );

    ack_sets_match( [ @args, @files ], \@expected, 'ack -c -h should return one line of results' );
}

SINGLE_FILE_COUNT: {
    my @args     = qw( Montresor -c -h );
    my @files    = ( 't/text/amontillado.txt' );
    my @expected = ( '3' );

    ack_sets_match( [ @args, @files ], \@expected, 'ack -c -h should return one line of results' );
}

NOT: {
    my @args     = qw( Montresor -c -h --not God );
    my @files    = ( 't/text/amontillado.txt' );
    my @expected = ( 2 );

    ack_sets_match( [ @args, @files ], \@expected, 'One line of results, with an accurate count' );
}

exit 0;
