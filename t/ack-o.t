#!perl

use warnings;
use strict;

use Test::More tests => 2;

use lib 't';
use Util;

prep_environment();

NO_O: {
    my @files = qw( t/text/gettysburg.txt );
    my @args = qw( the\\s+\\S+ );
    my @expected = line_split( <<'HERE' );
        but it can never forget what they did here. It is for us the living,
        rather, to be dedicated here to the unfinished work which they who
        here dedicated to the great task remaining before us -- that from these
        the last full measure of devotion -- that we here highly resolve that
        shall have a new birth of freedom -- and that government of the people,
        by the people, for the people, shall not perish from the earth.
HERE
    s/^\s+// for @expected;

    ack_lists_match( [ @args, @files ], \@expected, 'Find all the things without -o' );
}


WITH_O: {
    my @files = qw( t/text/gettysburg.txt );
    my @args = qw( the\\s+\\S+ -o );
    my @expected = line_split( <<'HERE' );
        the living,
        the unfinished
        the great
        the last
        the people,
        the people,
        the people,
        the earth.
HERE
    s/^\s+// for @expected;

    ack_lists_match( [ @args, @files ], \@expected, 'Find all the things with -o' );
}


done_testing();

exit 0;
