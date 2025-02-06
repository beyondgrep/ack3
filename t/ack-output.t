#!perl

use warnings;
use strict;

use Test::More tests => 46;

use lib 't';
use Util;

prep_environment();


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
