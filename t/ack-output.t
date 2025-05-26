#!perl

use warnings;
use strict;

use Test::More tests => 14;

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


FILENAME_SUBSTITUTION_MULTIPLE : {
    my @expected = line_split( <<'HERE' );
t/text/amontillado.txt:3:t/text/amontillado.txt:3:The thousand injuries of Fortunato I had borne as I best could; but
t/text/constitution.txt:38:t/text/constitution.txt:38:thirty Thousand, but each State shall have at Least one Representative;
t/text/constitution.txt:241:t/text/constitution.txt:241:Congress prior to the Year one thousand eight hundred and eight, but
t/text/constitution.txt:501:t/text/constitution.txt:501:which may be made prior to the Year One thousand eight hundred and eight
t/text/ozymandias.txt:3:t/text/ozymandias.txt:3:Stand in the desert... Near them, on the sand,
t/text/ozymandias.txt:14:t/text/ozymandias.txt:14:The lone and level sands stretch far away.
HERE

    my @files = qw( t/text );
    my @args = qw( sand --output=$f:$.:$_ --sort );
    my @results = run_ack( @args, @files );

    lists_match( \@results, \@expected, 'Multiple files with matching line' );
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


LITERAL_MULTIPLE_FILES : {
    my @expected = line_split( <<'HERE' );
t/text/amontillado.txt:3:literal
t/text/constitution.txt:38:literal
t/text/constitution.txt:241:literal
t/text/constitution.txt:501:literal
t/text/ozymandias.txt:3:literal
t/text/ozymandias.txt:14:literal
HERE

    my @files = qw( t/text );
    my @args = qw( sand --output=literal --sort );
    my @results = run_ack( @args, @files );

    lists_match( \@results, \@expected, 'Multiple files with literal replacement' );
}


done_testing();
exit 0;
