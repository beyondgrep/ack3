#!perl

use warnings;
use strict;
use 5.010;

use Test::More;

use lib 't';
use Util;

plan tests => 4;

prep_environment();

NO_BOOLEANS: {
    my @expected = line_split( <<'HERE' );
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
HERE

    my @files = qw( t/text/raven.txt );

    my @args = qw( -i nevermore );

    ack_sets_match( [ @args, @files ], \@expected, 'No booleans' );
}


NEVERMORE_NOT_QUOTH: {
    my @expected = line_split( <<'HERE' );
    With such name as "Nevermore."
    Then the bird said, "Nevermore."
    Of 'Never -- nevermore.'
    Meant in croaking "Nevermore."
    She shall press, ah, nevermore!
    Shall be lifted--nevermore!
HERE

    my @files = qw( t/text/raven.txt );

    my @args = qw( -i nevermore --not quoth );

    ack_sets_match( [ @args, @files ], \@expected, 'Nevermore not quoth' );
}


NEVERMORE_NOT_QUOTH_NOT_THE: {
    my @expected = line_split( <<'HERE' );
    With such name as "Nevermore."
    Of 'Never -- nevermore.'
    Meant in croaking "Nevermore."
    She shall press, ah, nevermore!
    Shall be lifted--nevermore!
HERE

    my @files = qw( t/text/raven.txt );

    my @args = qw( -i nevermore --not quoth --not the );

    ack_sets_match( [ @args, @files ], \@expected, 'Nevermore not quoth not the' );
}


QUOTH_NOT_NEVERMORE: {
    my @expected = line_split( <<'HERE' );
HERE

    my @files = qw( t/text/raven.txt );

    my @args = qw( -i quoth --not nevermore );

    ack_sets_match( [ @args, @files ], \@expected, 'Quoth not nevermore' );
}


done_testing();

exit 0;
