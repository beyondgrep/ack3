#!perl

use warnings;
use strict;

use Test::More tests => 6;

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

DASH_LC: {
    my @expected = qw(
        t/text/bill-of-rights.txt:1
        t/text/constitution.txt:29
    );

    my @args  = qw( congress -i -l -c --sort-files );
    my @files = qw( t/text );

    ack_sets_match( [ @args, @files ], \@expected, 'congress counts with -l -c' );
}

PIPE_INTO_C: {
    my $file = 't/text/raven.txt';
    my @args = qw( nevermore -i -c );
    my @results = pipe_into_ack( $file, @args );

    is_deeply( \@results, [ 11 ], 'Piping into ack --count should return one line of results' );
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

exit 0;
