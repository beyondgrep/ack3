#!perl

use warnings;
use strict;

use Test::More tests => 9;

use lib 't';
use Util;

prep_environment();

# Checks also beginning of file.



CONTEXT_OVERLAPPING_COLOR: {
    my $match_start = "\e[30;43m";
    my $match_end   = "\e[0m";
    my $line_end    = "\e[0m\e[K";

    my @expected = line_split( <<"HERE" );
This is line 03
This is line 04
This is line ${match_start}05${match_end}${line_end}
This is line ${match_start}06${match_end}${line_end}
This is line 07
This is line 08
HERE

    my $regex = '05|06';
    my @files = qw( t/text/numbered-text.txt );
    my @args = ( '--color', '-C', $regex );

    ack_lists_match( [ @args, @files ], \@expected, "Looking for $regex with overlapping contexts" );
}

CONTEXT_OVERLAPPING_COLOR_BEFORE: {
    my $match_start = "\e[30;43m";
    my $match_end   = "\e[0m";
    my $line_end    = "\e[0m\e[K";

    my @expected = line_split( <<"HERE" );
This is line 03
This is line 04
This is line ${match_start}05${match_end}${line_end}
This is line ${match_start}06${match_end}${line_end}
HERE

    my $regex = '05|06';
    my @files = qw( t/text/numbered-text.txt );
    my @args = ( '--color', '-B2', $regex );

    ack_lists_match( [ @args, @files ], \@expected, "Looking for $regex with overlapping contexts" );
}

CONTEXT_OVERLAPPING_COLOR_AFTER: {
    my $match_start = "\e[30;43m";
    my $match_end   = "\e[0m";
    my $line_end    = "\e[0m\e[K";

    my @expected = line_split( <<"HERE" );
This is line ${match_start}05${match_end}${line_end}
This is line ${match_start}06${match_end}${line_end}
This is line 07
This is line 08
HERE

    my $regex = '05|06';
    my @files = qw( t/text/numbered-text.txt );
    my @args = ( '--color', '-A2', $regex );

    ack_lists_match( [ @args, @files ], \@expected, "Looking for $regex with overlapping contexts" );
}

# -m3 should work properly and show only 3 matches with correct context
#    even though there is a 4th match in the after context of the third match
#    ("ratifying" in the last line)
CONTEXT_MAX_COUNT: {
    my @expected = line_split( <<'HERE' );
ratified by the Legislatures of three fourths of the several States, or
by Conventions in three fourths thereof, as the one or the other Mode of
Ratification may be proposed by the Congress; Provided that no Amendment
which may be made prior to the Year One thousand eight hundred and eight
--
The Ratification of the Conventions of nine States, shall be sufficient
for the Establishment of this Constitution between the States so ratifying
HERE

    my $regex = 'ratif';

    my @files = qw( t/text/constitution.txt );
    my @args = ( '-i', '-m3', '-A1', $regex );

    ack_lists_match( [ @args, @files ], \@expected, "Looking for $regex with -m3" );
}

# Highlighting works with context.
HIGHLIGHTING: {
    my @ack_args = qw( wretch -i -C5 --color );
    my @results = pipe_into_ack( 't/text/raven.txt', @ack_args );
    my @escaped_lines = grep { /\e/ } @results;
    is( scalar @escaped_lines, 1, 'Only one line highlighted' );
    is( scalar @results, 11, 'Expecting altogether 11 lines back' );
}

# Grouping works with context (single file).
GROUPING_SINGLE_FILE: {
    my $target_file = reslash( 't/etc/shebang.py.xxx' );
    my @expected = line_split( <<"HERE" );
$target_file
1:#!/usr/bin/python
HERE

    my $regex = 'python';
    my @args = ( '-t', 'python', '--group', '-C', $regex );

    ack_lists_match( [ @args ], \@expected, "Looking for $regex in Python files with grouping" );
}


# Grouping works with context and multiple files.
# i.e. a separator line between different matches in the same file and no separator between files
GROUPING_MULTIPLE_FILES: {
    my @expected = line_split( <<"HERE" );
t/text/amontillado.txt
258-As I said these words I busied myself among the pile of bones of
259:which I have before spoken. Throwing them aside, I soon uncovered

t/text/raven.txt
31-But the silence was unbroken, and the stillness gave no token,
32:And the only word there spoken was the whispered word, "Lenore?"
--
70-
71:Startled at the stillness broken by reply so aptly spoken,
--
114-"Get thee back into the tempest and the Night's Plutonian shore!
115:Leave no black plume as a token of that lie thy soul hath spoken!
HERE

    my $regex = 'spoken';
    my @files = qw( t/text/ );
    my @args = ( '--group', '-B1', '--sort-files', $regex );

    ack_lists_match( [ @args, @files ], \@expected, "Looking for $regex in multiple files with grouping" );
}

# See https://github.com/beyondgrep/ack2/issues/326 and links there for details.
WITH_COLUMNS_AND_CONTEXT: {
    my @files = qw( t/text/ );
    my @expected = line_split( <<'HERE' );
t/text/bill-of-rights.txt-1-# Amendment I
t/text/bill-of-rights.txt-2-
t/text/bill-of-rights.txt-3-Congress shall make no law respecting an establishment of religion,
t/text/bill-of-rights.txt:4:60:or prohibiting the free exercise thereof; or abridging the freedom of
t/text/bill-of-rights.txt-5-speech, or of the press; or the right of the people peaceably to assemble,
t/text/bill-of-rights.txt-6-and to petition the Government for a redress of grievances.
t/text/bill-of-rights.txt-7-
t/text/bill-of-rights.txt-8-# Amendment II
t/text/bill-of-rights.txt-9-
--
t/text/gettysburg.txt-18-fought here have thus far so nobly advanced. It is rather for us to be
t/text/gettysburg.txt-19-here dedicated to the great task remaining before us -- that from these
t/text/gettysburg.txt-20-honored dead we take increased devotion to that cause for which they gave
t/text/gettysburg.txt-21-the last full measure of devotion -- that we here highly resolve that
t/text/gettysburg.txt-22-these dead shall not have died in vain -- that this nation, under God,
t/text/gettysburg.txt:23:27:shall have a new birth of freedom -- and that government of the people,
t/text/gettysburg.txt-24-by the people, for the people, shall not perish from the earth.
HERE

    my $regex = 'freedom';
    my @args = ( '--column', '-C5', '-H', '--sort-files', $regex );

    ack_lists_match( [ @args, @files ], \@expected, "Looking for $regex" );
}

done_testing();

exit 0;
