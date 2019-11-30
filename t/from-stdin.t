#!perl

use warnings;
use strict;

use Test::More tests => 3;

use lib 't';
use Util;

prep_environment();


PIPE_INTO_ACK: {
    my @expected = line_split( <<'END' );
    Of 'Never -- nevermore.'
    She shall press, ah, nevermore!
    Shall be lifted--nevermore!
END

    my $file = 't/text/raven.txt';
    my @args = qw( nevermore );
    my @results = pipe_into_ack( $file, @args );

    is_deeply( \@results, \@expected, 'Piping a file' );
}


PIPE_INTO_DASH_I: {
    my @expected = line_split( <<'END' );
    Quoth the Raven, "Nevermore."
    With such name as "Nevermore."
    Then the bird said, "Nevermore."
    Of 'Never -- nevermore.'
    Meant in croaking "Nevermore."
    She shall press, ah, nevermore!
    Quoth the Raven, "Nevermore."
    Quoth the Raven, "Nevermore."
    Quoth the Raven, "Nevermore."
    Quoth the Raven, "Nevermore."
    Shall be lifted--nevermore!
END

    my $file = 't/text/raven.txt';
    my @args = qw( nevermore -i );
    my @results = pipe_into_ack( $file, @args );

    is_deeply( \@results, \@expected, 'Piping a file with -i' );
}


PIPE_INTO_DASH_C: {
    my $file = 't/text/raven.txt';
    my @args = qw( nevermore -i -c );
    my @results = pipe_into_ack( $file, @args );

    is_deeply( \@results, [ 11 ], 'Piping into ack --count should return one line of results' );
}


exit 0;
