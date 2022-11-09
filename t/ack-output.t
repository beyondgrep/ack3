#!perl

use warnings;
use strict;

use Test::More tests => 46;

use lib 't';
use Util;

prep_environment();

DOLLAR_1: {
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


DOLLAR_UNDERSCORE: {
    my @expected = line_split( <<'HERE' );
shall have a new birth of freedom -- and that government of the people,xshall have a new birth of freedom -- and that government of the people,
HERE

    my @files = qw( t/text/gettysburg.txt );
    my @args = qw( free --output=$_x$_ );
    my @results = run_ack( @args, @files );

    lists_match( \@results, \@expected, 'Matching line' );
}


ARG_MULTIPLE_FILES: {
    # Note the first line is there twice because it matches twice.
    my @expected = line_split( <<'HERE' );
or prohibiting the free exercise thereof; or abridging the freedom of
or prohibiting the free exercise thereof; or abridging the freedom of
A well regulated Militia, being necessary to the security of a free State,
Number of free Persons, including those bound to Service for a Term
shall have a new birth of freedom -- and that government of the people,
HERE

    my @files = qw( t/text );
    my @args = qw( free --sort-files -h --output=$_ );
    my @results = run_ack( @args, @files );

    lists_match( \@results, \@expected, 'Matching line' );
}


# Find a match in multiple files, and output it in double quotes.
DOUBLE_QUOTES: {
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


MATCH: {
    my @expected = (
        'free'
    );

    my @files = qw( t/text/gettysburg.txt );
    my @args = qw( free --output=$& );
    my @results = run_ack( @args, @files );

    lists_match( \@results, \@expected, 'Part of a line matching pattern' );
}

MATCH_MULTIPLE_FILES: {
    my @expected = line_split( <<'HERE' );
t/text/bill-of-rights.txt:4:free
t/text/bill-of-rights.txt:4:free
t/text/bill-of-rights.txt:10:free
t/text/constitution.txt:32:free
t/text/gettysburg.txt:23:free
HERE

    my @files = qw ( t/text );
    my @args = qw( free --sort-files --output=$& );
    my @results = run_ack( @args, @files );

    lists_match( \@results, \@expected, 'Part of a line matching pattern' );
}

PREMATCH: {
    # No HEREDOC here since we do not want our editor/IDE messing with trailing whitespace.
    my @expected = (
        'shall have a new birth of '
    );

    my @files = qw( t/text/gettysburg.txt );
    my @args = qw( freedom --output=$` );
    my @results = run_ack( @args, @files );

    lists_match( \@results, \@expected, 'Part of a line preceding match' );
}

PREMATCH_MULTIPLE_FILES: {
    # No HEREDOC here since we do not want our editor/IDE messing with trailing whitespace.
    my @expected = (
        'or prohibiting the free exercise thereof; or abridging the ',
        'shall have a new birth of '
    );

    my @files = qw( t/text/);
    my @args = qw( freedom -h --sort-files --output=$` );
    my @results = run_ack( @args, @files );

    lists_match( \@results, \@expected, 'Part of a line preceding match' );
}

POSTMATCH: {
    my @expected = split( /\n/, <<'HERE' );
 -- and that government of the people,
HERE

    my @files = qw( t/text/gettysburg.txt );
    my @args = qw( freedom --output=$' );
    my @results = run_ack( @args, @files );

    lists_match( \@results, \@expected, 'Part of a line that follows match' );
}

POSTMATCH_MULTIPLE_FILES: {
    my @expected = line_split( <<'HERE' );
 of
 -- and that government of the people,
HERE

    my @files = qw( t/text/ );
    my @args = qw( freedom -h --sort-files --output=$' );
    my @results = run_ack( @args, @files );

    lists_match( \@results, \@expected, 'Part of a line that follows match' );
}

SUBPATTERN_MATCH: {
    my @expected = (
        'love-God-Montresor'
    );

    my @files = qw( t/text/amontillado.txt );
    my @args = qw( (love).+(God).+(Montresor) --output=$1-$2-$3 );
    my @results = run_ack( @args, @files );

    lists_match( \@results, \@expected, 'Capturing parentheses match' );
}

SUBPATTERN_MATCH_MULTIPLE_FILES: {
    my @expected = line_split( <<'HERE' );
the-free-exercise
a-free-State
of-free-Persons
HERE

    my @files = qw( t/text/ );
    my @args = qw( (\w+)\s(free)\s(\w+) -h --sort-files --output=$1-$2-$3 );
    my @results = run_ack( @args, @files );

    lists_match( \@results, \@expected, 'Capturing parentheses match' );
}

INPUT_LINE_NUMBER: {
    my @expected = (
      'line:15'
    );

    my @files = qw( t/text/bill-of-rights.txt );
    my @args = qw( quartered --output=line:$. );
    my @results = run_ack( @args, @files );

    lists_match( \@results, \@expected, 'Line number' );
}

INPUT_LINE_NUMBER_MULTIPLE_FILES: {
    my @expected = line_split( <<'HERE' );
t/text/bill-of-rights.txt:4:line:4
t/text/bill-of-rights.txt:4:line:4
t/text/bill-of-rights.txt:10:line:10
t/text/constitution.txt:32:line:32
t/text/gettysburg.txt:23:line:23
HERE

    my @files = qw( t/text/ );
    my @args = qw( free --sort-files --output=line:$. );
    my @results = run_ack( @args, @files );

    lists_match( \@results, \@expected, 'Line number' );
}

LAST_PAREN_MATCH: {
    my @expected = line_split( <<'HERE' );
t/text/amontillado.txt:124:love
t/text/amontillado.txt:309:love
t/text/amontillado.txt:311:love
t/text/constitution.txt:267:hate
HERE

    my @files = qw( t/text/ );
    my @args = qw( (love)|(hate) --sort-files --output=$+ );
    my @results = run_ack( @args, @files );

    lists_match( \@results, \@expected, 'Last paren match' );
}


COMBOS_1: {
    my @expected = line_split( <<'HERE' );
t/text/amontillado.txt:124:love-124-d; you are happy,
t/text/amontillado.txt:309:love-309- of God, Montresor!"
t/text/amontillado.txt:311:love-311- of God!"
t/text/constitution.txt:267:hate-267-ver, from any King, Prince, or foreign State.
HERE

    my @files = qw( t/text/ );
    my @args = qw( (love)|(hate) --sort-files --output=$+-$.-$' );
    my @results = run_ack( @args, @files );

    lists_match( \@results, \@expected, 'Combos 1' );
}


COMBOS_2: {
    my @expected = line_split( <<'HERE' );
t/text/amontillado.txt:124:happy-happy-happy
t/text/raven.txt:73:happy-happy-happy
HERE

    my @files = qw( t/text/ );
    my @args = qw( (happy) --sort-files -i --output=$1-$&-$1 );
    my @results = run_ack( @args, @files );

    lists_match( \@results, \@expected, 'Combos 2' );
}


COMBOS_3: {
    my @expected = line_split( <<'HERE' );
t/text/amontillado.txt:124:precious. You are rich, respected, admired, beloved; you are ---,--happy
t/text/raven.txt:73:Caught from some un--- master whom unmerciful Disaster--happy
HERE

    my @files = qw( t/text/ );
    my @args = qw( (happy) --sort-files -i --output=$`---$'--$+ );
    my @results = run_ack( @args, @files );

    lists_match( \@results, \@expected, 'Combos 2' );
}


NUMERIC_SUBSTITUTIONS: {
    # Make sure that substitutions don't affect future substitutions.
    my @expected = line_split( <<'HERE' );
t/text/constitution.txt:269:Section 10 on line 269
HERE

    my @files = qw( t/text/bill-of-rights.txt t/text/constitution.txt );
    my @args = ( '(\d\d)', '--output=Section $1 on line $.' );
    my @results = run_ack( @args, @files );

    lists_match( \@results, \@expected, 'Numeric substitutions' );
}


CHARACTER_SUBSTITUTIONS: {
    # Make sure that substitutions don't affect future substitutions.
    my @expected = line_split( <<"HERE" );
t/text/bill-of-rights.txt:15:No Soldier shall, in time of peace be
in any house, without\tin any house, without
HERE

    my @files = qw( t/text/ );
    my @args = ( '\s+quartered\s+(.+)', '--output=$`\n$1\t$1' );
    my @results = run_ack( @args, @files );

    lists_match( \@results, \@expected, 'Character substitutions' );
}


# $f is the filename, needed for grep, emulating ack2 $filename:$lineno:$_
FILENAME_SUBSTITUTION_1 : {
    my @expected = line_split( <<'HERE' );
t/text/ozymandias.txt:4:Half sunk, a shattered visage lies, whose frown,
HERE

    my @files = qw( t/text/ozymandias.txt );
    my @args = qw( visage --output=$f:$.:$_ );
    my @results = run_ack( @args, @files );

    lists_match( \@results, \@expected, 'Filename with matching line' );
}


FILENAME_SUBSTITUTION_2 : {
    my @expected = line_split( <<'HERE' );
t/text/ozymandias.txt:4:visage
HERE

    my @files = qw( t/text/ozymandias.txt );
    my @args = qw( visage --output=$f:$.:$& );
    my @results = run_ack( @args, @files );

    lists_match( \@results, \@expected, 'Filename with match' );
}


FILENAME_SUBSTITUTION_3 : {
    my @expected = line_split( <<'HERE' );
t/text/ozymandias.txt:4:visage
HERE

    my @files = qw( t/text/ozymandias.txt );
    my @args = qw( (visage) --output=$f:$.:$+ );
    my @results = run_ack( @args, @files );

    lists_match( \@results, \@expected, 'Filename with last match' );
}


NO_SPECIALS_IN_OUTPUT_EXPRESSION : {
    my @expected = line_split( <<'HERE' );
literal
literal
HERE

    my @files = qw( t/text/ozymandias.txt );
    my @args = qw( sand --output=literal );
    my @results = run_ack( @args, @files );

    lists_match( \@results, \@expected, 'Filename with last match' );
}


done_testing();
exit 0;
