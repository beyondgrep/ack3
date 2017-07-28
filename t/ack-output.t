#!perl -T

use warnings;
use strict;

use Test::More tests => 34;

use lib 't';
use Util;

prep_environment();

ARG: {
    my @expected = (
      'Sink, swim, go down with the shipxSink, swim, go down with the ship'
    );

    my @files = qw( t/text/freedom-of-choice.txt );
    my @args = qw( swim --output=$_x$_ );
    my @results = run_ack( @args, @files );

    lists_match( \@results, \@expected, 'Matching line' );
}

ARG_MULTIPLE_FILES: {
    my @expected = line_split( <<'HERE' );
And there you were
He stood there lookin' at me and I saw him smile.
And I knew I wouldn't be there to help ya along.
In the case of Christianity and Judaism there exists the belief
HERE

    my @files = qw( t/text );
    my @args = qw( there --sort-files -h --output=$_ );
    my @results = run_ack( @args, @files );

    lists_match( \@results, \@expected, 'Matching line' );
}

MATCH: {
    my @expected = (
      'swim'
    );

    my @files = qw( t/text/freedom-of-choice.txt );
    my @args = qw( swim --output=$& );
    my @results = run_ack( @args, @files );

    lists_match( \@results, \@expected, 'Part of a line matching pattern' );
}

MATCH_MULTIPLE_FILES: {
    my @expected = line_split( <<'HERE' );
t/text/4th-of-july.txt:22:there
t/text/boy-named-sue.txt:48:there
t/text/boy-named-sue.txt:52:there
t/text/science-of-myth.txt:3:there
HERE

    my @files = qw ( t/text );
    my @args = qw( there --sort-files --output=$& );
    my @results = run_ack( @args, @files );

    lists_match( \@results, \@expected, 'Part of a line matching pattern' );
}

PREMATCH: {
    my @expected = (
      'Sink, '
    );

    my @files = qw( t/text/freedom-of-choice.txt );
    my @args = qw( swim --output=$` );
    my @results = run_ack( @args, @files );

    lists_match( \@results, \@expected, 'Part of a line preceding match' );
}

PREMATCH_MULTIPLE_FILES: {

    # No HEREDOC here since we do not want our editor/IDE messing with trailing whitespace.
    my @expected = (
        'And ',
        'He stood ',
        'And I knew I wouldn\'t be ',
        'In the case of Christianity and Judaism ',
    );

    my @files = qw( t/text/);
    my @args = qw( there -h --sort-files --output=$` );
    my @results = run_ack( @args, @files );

    lists_match( \@results, \@expected, 'Part of a line preceding match' );
}

POSTMATCH: {
    my @expected = (
      ', go down with the ship'
    );

    my @files = qw( t/text/freedom-of-choice.txt );
    my @args = qw( swim --output=$' );
    my @results = run_ack( @args, @files );

    lists_match( \@results, \@expected, 'Part of a line that follows match' );
}

POSTMATCH_MULTIPLE_FILES: {
    my @expected = line_split( <<'HERE' );
 you were
 lookin' at me and I saw him smile.
 to help ya along.
 exists the belief
HERE

    my @files = qw( t/text/ );
    my @args = qw( there -h --sort-files --output=$' );
    my @results = run_ack( @args, @files );

    lists_match( \@results, \@expected, 'Part of a line that follows match' );
}

SUBPATTERN_MATCH: {
    my @expected = (
      'Sink-swim-ship'
    );

    my @files = qw( t/text/freedom-of-choice.txt );
    my @args = qw( ^(Sink).+(swim).+(ship)$ --output=$1-$2-$3 );
    my @results = run_ack( @args, @files );

    lists_match( \@results, \@expected, 'Capturing parentheses match' );
}

SUBPATTERN_MATCH_MULTIPLE_FILES: {
    my @expected = line_split( <<'HERE' );
And-there-you
stood-there-lookin
be-there-to
Judaism-there-exists
HERE

    my @files = qw( t/text/ );
    my @args = qw( (\w+)\s(there)\s(\w+) -h --sort-files --output=$1-$2-$3 );
    my @results = run_ack( @args, @files );

    lists_match( \@results, \@expected, 'Capturing parentheses match' );
}

INPUT_LINE_NUMBER: {
    my @expected = (
      'line:3'
    );

    my @files = qw( t/text/freedom-of-choice.txt );
    my @args = qw( swim --output=line:$. );
    my @results = run_ack( @args, @files );

    lists_match( \@results, \@expected, 'Line number' );
}

INPUT_LINE_NUMBER_MULTIPLE_FILES: {
    my @expected = line_split( <<'HERE' );
t/text/4th-of-july.txt:22:line:22
t/text/boy-named-sue.txt:48:line:48
t/text/boy-named-sue.txt:52:line:52
t/text/science-of-myth.txt:3:line:3
HERE

    my @files = qw( t/text/ );
    my @args = qw( there --sort-files --output=line:$. );
    my @results = run_ack( @args, @files );

    lists_match( \@results, \@expected, 'Line number' );
}

LAST_PAREN_MATCH: {
    my @expected = line_split( <<'HERE' );
t/text/4th-of-july.txt:12:love
t/text/boy-named-sue.txt:58:hate
t/text/boy-named-sue.txt:70:hate
t/text/shut-up-be-happy.txt:5:love
HERE

    my @files = qw( t/text/ );
    my @args = qw( (love)|(hate) --sort-files --output=$+ );
    my @results = run_ack( @args, @files );

    lists_match( \@results, \@expected, 'Last paren match' );
}


COMBOS_1: {
    my @expected = line_split( <<'HERE' );
t/text/4th-of-july.txt:12:love-12- me,
t/text/boy-named-sue.txt:58:hate-58- me, and you got the right
t/text/boy-named-sue.txt:70:hate-70- that name!
t/text/shut-up-be-happy.txt:5:love-5-d ones, insurance agents or attorneys.
HERE

    my @files = qw( t/text/ );
    my @args = qw( (love)|(hate) --sort-files --output=$+-$.-$' );
    my @results = run_ack( @args, @files );

    lists_match( \@results, \@expected, 'Combos 1' );
}

COMBOS_2: {
    my @expected = line_split( <<'HERE' );
t/text/4th-of-july.txt:13:happy-happy-happy
t/text/shut-up-be-happy.txt:20:happy-happy-happy
t/text/shut-up-be-happy.txt:23:happy-happy-happy
t/text/shut-up-be-happy.txt:26:Happy-Happy-Happy
HERE

    my @files = qw( t/text/ );
    my @args = qw( (happy) --sort-files -i --output=$1-$&-$1 );
    my @results = run_ack( @args, @files );

    lists_match( \@results, \@expected, 'Combos 2' );
}


COMBOS_3: {
    my @expected = line_split( <<'HERE' );
t/text/4th-of-july.txt:13:And you're --- to be with me on the 4th of July--happy
t/text/shut-up-be-happy.txt:20:Shut up! Be ---.--happy
t/text/shut-up-be-happy.txt:23:Be ---.--happy
t/text/shut-up-be-happy.txt:26:    -- "Shut Up, Be ---", Jello Biafra--Happy
HERE

    my @files = qw( t/text/ );
    my @args = qw( (happy) --sort-files -i --output=$`---$'--$+ );
    my @results = run_ack( @args, @files );

    lists_match( \@results, \@expected, 'Combos 2' );
}


NUMERIC_SUBSTITUTIONS: {
    # Make sure that substitutions don't affect future substitutions.
    my @expected = line_split( <<'HERE' );
t/text/shut-up-be-happy.txt:9:Ninety-five is 95 and seventy-six is 76
HERE

    my @files = qw( t/text/ );
    my @args = ( '(\d+) PM', '--output=Ninety-five is $.5 and seventy-six is $16' );
    my @results = run_ack( @args, @files );

    lists_match( \@results, \@expected, 'Numeric substitutions' );
}


done_testing();
exit 0;
