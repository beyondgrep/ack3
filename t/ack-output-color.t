#!perl

use warnings;
use strict;

use Test::More;
use Term::ANSIColor qw(color);

use lib 't';
use Util;

if ( not has_io_pty() ) {
    plan skip_all => q{You need to install IO::Pty to run this test};
    exit(0);
}

plan tests => 26;

prep_environment();

my $CFN      = color( 'bold green' );
my $CRESET   = color( 'reset' );
my $CLN      = color( 'bold yellow' );
my $CM       = color( 'black on_yellow' );
my $LINE_END = "\e[0m\e[K";

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
    my @results = run_ack_interactive( @args, @files );

    lists_match( \@results, \@expected, 'Matching line' );
}


ARG_MULTIPLE_FILES: {
    # Note the first line is there twice because it matches twice.
    # Blank lines are a result of '--break' being enabled by default
    my @expected = line_split( <<'HERE' );
or prohibiting the free exercise thereof; or abridging the freedom of
or prohibiting the free exercise thereof; or abridging the freedom of
A well regulated Militia, being necessary to the security of a free State,

Number of free Persons, including those bound to Service for a Term

shall have a new birth of freedom -- and that government of the people,
HERE

    my @files = qw( t/text );
    my @args = qw( free --sort-files -h --output=$_ );
    my @results = run_ack_interactive( @args, @files );

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
    my @results = run_ack_interactive( @args, @files );

    lists_match( \@results, \@expected, 'Part of a line matching pattern' );
}

MATCH_MULTIPLE_FILES: {
    my @expected = line_split( <<"HERE" );
${CFN}t/text/bill-of-rights.txt${CRESET}
${CLN}4${CRESET}:free
${CLN}4${CRESET}:free
${CLN}10${CRESET}:free

${CFN}t/text/constitution.txt${CRESET}
${CLN}32${CRESET}:free

${CFN}t/text/gettysburg.txt${CRESET}
${CLN}23${CRESET}:free
HERE

    my @files = qw ( t/text );
    my @args = qw( free --sort-files --output=$& );
    my @results = run_ack_interactive( @args, @files );

    lists_match( \@results, \@expected, 'Part of a line matching pattern' );
}

PREMATCH: {
    # No HEREDOC here since we do not want our editor/IDE messing with trailing whitespace.
    my @expected = (
        'shall have a new birth of '
    );

    my @files = qw( t/text/gettysburg.txt );
    my @args = qw( freedom --output=$` );
    my @results = run_ack_interactive( @args, @files );

    lists_match( \@results, \@expected, 'Part of a line preceding match' );
}

PREMATCH_MULTIPLE_FILES: {
    # No HEREDOC here since we do not want our editor/IDE messing with trailing whitespace.
    my @expected = (
        'or prohibiting the free exercise thereof; or abridging the ',
        '',
        'shall have a new birth of '
    );

    my @files = qw( t/text/);
    my @args = qw( freedom -h --sort-files --output=$` );
    my @results = run_ack_interactive( @args, @files );

    lists_match( \@results, \@expected, 'Part of a line preceding match' );
}

POSTMATCH: {
    my @expected = split( /\n/, <<'HERE' );
 -- and that government of the people,
HERE

    my @files = qw( t/text/gettysburg.txt );
    my @args = qw( freedom --output=$' );
    my @results = run_ack_interactive( @args, @files );

    lists_match( \@results, \@expected, 'Part of a line that follows match' );
}

POSTMATCH_MULTIPLE_FILES: {
    my @expected = line_split( <<'HERE' );
 of

 -- and that government of the people,
HERE

    my @files = qw( t/text/ );
    my @args = qw( freedom -h --sort-files --output=$' );
    my @results = run_ack_interactive( @args, @files );

    lists_match( \@results, \@expected, 'Part of a line that follows match' );
}

SUBPATTERN_MATCH: {
    my @expected = (
        'love-God-Montresor'
    );

    my @files = qw( t/text/amontillado.txt );
    my @args = qw( (love).+(God).+(Montresor) --output=$1-$2-$3 );
    my @results = run_ack_interactive( @args, @files );

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
    my @results = run_ack_interactive( @args, @files );

    lists_match( \@results, \@expected, 'Capturing parentheses match' );
}

INPUT_LINE_NUMBER: {
    my @expected = (
      'line:15'
    );

    my @files = qw( t/text/bill-of-rights.txt );
    my @args = qw( quartered --output=line:$. );
    my @results = run_ack_interactive( @args, @files );

    lists_match( \@results, \@expected, 'Line number' );
}

INPUT_LINE_NUMBER_MULTIPLE_FILES: {
    my @expected = line_split( <<"HERE" );
${CFN}t/text/bill-of-rights.txt${CRESET}
${CLN}4${CRESET}:line:4
${CLN}4${CRESET}:line:4
${CLN}10${CRESET}:line:10

${CFN}t/text/constitution.txt${CRESET}
${CLN}32${CRESET}:line:32

${CFN}t/text/gettysburg.txt${CRESET}
${CLN}23${CRESET}:line:23
HERE

    my @files = qw( t/text/ );
    my @args = qw( free --sort-files --output=line:$. );
    my @results = run_ack_interactive( @args, @files );

    lists_match( \@results, \@expected, 'Line number' );
}

LAST_PAREN_MATCH: {
    my @expected = line_split( <<"HERE" );
${CFN}t/text/amontillado.txt${CRESET}
${CLN}124${CRESET}:love
${CLN}309${CRESET}:love
${CLN}311${CRESET}:love

${CFN}t/text/constitution.txt${CRESET}
${CLN}267${CRESET}:hate
HERE

    my @files = qw( t/text/ );
    my @args = qw( (love)|(hate) --sort-files --output=$+ );
    my @results = run_ack_interactive( @args, @files );

    lists_match( \@results, \@expected, 'Last paren match' );
}


COMBOS_1: {
    my @expected = line_split( <<"HERE" );
${CFN}t/text/amontillado.txt${CRESET}
${CLN}124${CRESET}:love-124-d; you are happy,
${CLN}309${CRESET}:love-309- of God, Montresor!"
${CLN}311${CRESET}:love-311- of God!"

${CFN}t/text/constitution.txt${CRESET}
${CLN}267${CRESET}:hate-267-ver, from any King, Prince, or foreign State.
HERE

    my @files = qw( t/text/ );
    my @args = qw( (love)|(hate) --sort-files --output=$+-$.-$' );
    my @results = run_ack_interactive( @args, @files );

    lists_match( \@results, \@expected, 'Combos 1' );
}


COMBOS_2: {
    my @expected = line_split( <<"HERE" );
${CFN}t/text/amontillado.txt${CRESET}
${CLN}124${CRESET}:happy-happy-happy

${CFN}t/text/raven.txt${CRESET}
${CLN}73${CRESET}:happy-happy-happy
HERE

    my @files = qw( t/text/ );
    my @args = qw( (happy) --sort-files -i --output=$1-$&-$1 );
    my @results = run_ack_interactive( @args, @files );

    lists_match( \@results, \@expected, 'Combos 2' );
}


COMBOS_3: {
    my @expected = line_split( <<"HERE" );
${CFN}t/text/amontillado.txt${CRESET}
${CLN}124${CRESET}:precious. You are rich, respected, admired, beloved; you are ---,--happy

${CFN}t/text/raven.txt${CRESET}
${CLN}73${CRESET}:Caught from some un--- master whom unmerciful Disaster--happy
HERE

    my @files = qw( t/text/ );
    my @args = qw( (happy) --sort-files -i --output=$`---$'--$+ );
    my @results = run_ack_interactive( @args, @files );

    lists_match( \@results, \@expected, 'Combos 2' );
}


NUMERIC_SUBSTITUTIONS: {
    # Make sure that substitutions don't affect future substitutions.
    my @expected = line_split( <<"HERE" );
${CFN}t/text/constitution.txt${CRESET}
${CLN}269${CRESET}:Section 10 on line 269
HERE

    my @files = qw( t/text/bill-of-rights.txt t/text/constitution.txt );
    my @args = ( '(\d\d)', '--output=Section $1 on line $.' );
    my @results = run_ack_interactive( @args, @files );

    lists_match( \@results, \@expected, 'Numeric substitutions' );
}


CHARACTER_SUBSTITUTIONS: {
    # Make sure that substitutions don't affect future substitutions.
    my @expected = line_split( <<"HERE" );
${CFN}t/text/bill-of-rights.txt${CRESET}
${CLN}15${CRESET}:No Soldier shall, in time of peace be
in any house, without\tin any house, without
HERE

    my @files = qw( t/text/ );
    my @args = ( '\s+quartered\s+(.+)', '--output=$`\n$1\t$1' );
    my @results = run_ack_interactive( @args, @files );

    lists_match( \@results, \@expected, 'Character substitutions' );
}


# $f is the filenname, needed for grep, emulating ack2 $filename:$lineno:$_
FILENAME_SUBSTITUTION_1 : {
    my @expected = line_split( <<'HERE' );
t/text/ozymandias.txt:4:Half sunk, a shattered visage lies, whose frown,
HERE

    my @files = qw( t/text/ozymandias.txt );
    my @args = qw( visage --output=$f:$.:$_ );
    my @results = run_ack_interactive( @args, @files );

    lists_match( \@results, \@expected, 'Filename with matching line' );
}


FILENAME_SUBSTITUTION_2 : {
    my @expected = line_split( <<'HERE' );
t/text/ozymandias.txt:4:visage
HERE

    my @files = qw( t/text/ozymandias.txt );
    my @args = qw( visage --output=$f:$.:$& );
    my @results = run_ack_interactive( @args, @files );

    lists_match( \@results, \@expected, 'Filename with match' );
}


FILENAME_SUBSTITUTION_3 : {
    my @expected = line_split( <<'HERE' );
t/text/ozymandias.txt:4:visage
HERE

    my @files = qw( t/text/ozymandias.txt );
    my @args = qw( (visage) --output=$f:$.:$+ );
    my @results = run_ack_interactive( @args, @files );

    lists_match( \@results, \@expected, 'Filename with last match' );
}

FILENAME_SUBSTITUTION_MULTIPLE : {
    my @expected = line_split( <<"HERE" );
${CFN}t/text/amontillado.txt${CRESET}
${CLN}3${CRESET}:t/text/amontillado.txt:3:The thousand injuries of Fortunato I had borne as I best could; but

${CFN}t/text/constitution.txt${CRESET}
${CLN}38${CRESET}:t/text/constitution.txt:38:thirty Thousand, but each State shall have at Least one Representative;
${CLN}241${CRESET}:t/text/constitution.txt:241:Congress prior to the Year one thousand eight hundred and eight, but
${CLN}501${CRESET}:t/text/constitution.txt:501:which may be made prior to the Year One thousand eight hundred and eight

${CFN}t/text/ozymandias.txt${CRESET}
${CLN}3${CRESET}:t/text/ozymandias.txt:3:Stand in the desert... Near them, on the sand,
${CLN}14${CRESET}:t/text/ozymandias.txt:14:The lone and level sands stretch far away.
HERE

    my @files = qw( t/text );
    my @args = qw( sand --output=$f:$.:$_ --sort );
    my @results = run_ack_interactive( @args, @files );

    lists_match( \@results, \@expected, 'Multiple files with matching line' );
}


NO_SPECIALS_IN_OUTPUT_EXPRESSION : {
    my @expected = line_split( <<'HERE' );
literal
literal
HERE

    my @files = qw( t/text/ozymandias.txt );
    my @args = qw( sand --output=literal );
    my @results = run_ack_interactive( @args, @files );

    lists_match( \@results, \@expected, 'Filename with last match' );
}

LITERAL_MULTIPLE_FILES : {
    my @expected = line_split( <<"HERE" );
${CFN}t/text/amontillado.txt${CRESET}
${CLN}3${CRESET}:literal

${CFN}t/text/constitution.txt${CRESET}
${CLN}38${CRESET}:literal
${CLN}241${CRESET}:literal
${CLN}501${CRESET}:literal

${CFN}t/text/ozymandias.txt${CRESET}
${CLN}3${CRESET}:literal
${CLN}14${CRESET}:literal
HERE

    my @files = qw( t/text );
    my @args = qw( sand --output=literal --sort );
    my @results = run_ack_interactive( @args, @files );

    lists_match( \@results, \@expected, 'Multiple files with literal replacement' );
}


done_testing();
exit 0;
