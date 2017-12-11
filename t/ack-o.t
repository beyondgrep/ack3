#!perl -T

use warnings;
use strict;

use Test::More tests => 4;

use lib 't';
use Util;

prep_environment();

NO_O: {
    my @files = qw( t/text/gettysburg.txt );
    my @args = qw( the\\s+\\S+ );
    my @expected = line_split( <<'EOF' );
        but it can never forget what they did here. It is for us the living,
        rather, to be dedicated here to the unfinished work which they who
        here dedicated to the great task remaining before us -- that from these
        the last full measure of devotion -- that we here highly resolve that
        shall have a new birth of freedom -- and that government of the people,
        by the people, for the people, shall not perish from the earth.
EOF
    s/^\s+// for @expected;

    ack_lists_match( [ @args, @files ], \@expected, 'Find all the things without -o' );
}


WITH_O: {
    my @files = qw( t/text/gettysburg.txt );
    my @args = qw( the\\s+\\S+ -o );
    my @expected = line_split( <<'EOF' );
        the living,
        the unfinished
        the great
        the last
        the people,
        the people,
        the people,
        the earth.
EOF
    s/^\s+// for @expected;

    ack_lists_match( [ @args, @files ], \@expected, 'Find all the things with -o' );
}


# Give an output function and find match in multiple files (so print filenames, just like grep -o).
WITH_OUTPUT: {
    my @files = qw( t/text/ );
    my @args = qw/ --output=x$1x free(\\S+) --sort-files /;

    my @target_file = map { reslash($_) } qw(
        t/text/bill-of-rights.txt
        t/text/gettysburg.txt
    );
    my @expected = (
        "$target_file[0]:4:xdomx",
        "$target_file[1]:23:xdomx",
    );

    ack_sets_match( [ @args, @files ], \@expected, 'Find all the things with --output function' );
}


# Find a match in multiple files, and output it in double quotes.
OUTPUT_DOUBLE_QUOTES: {
    my @files = qw( t/text/ );
    my @args  = ( '--output="$1"', '(free\\w*)', '--sort-files' );

    my @target_file = map { reslash($_) } qw(
        t/text/bill-of-rights.txt
        t/text/constitution.txt
        t/text/gettysburg.txt
    );
    my @expected = (
        qq{$target_file[0]:4:"free"},
        qq{$target_file[0]:4:"freedom"},
        qq{$target_file[0]:10:"free"},
        qq{$target_file[1]:32:"free"},
        qq{$target_file[2]:23:"freedom"},
    );

    ack_sets_match( [ @args, @files ], \@expected, 'Find all the things with --output function' );
}

done_testing();
