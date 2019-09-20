#!perl

use warnings;
use strict;

use Test::More;

use lib 't';
use Util;

plan tests => 4;

prep_environment();

subtest 'whitespace+dollar normal' => sub {
    plan tests => 4;

    my @expected = ();

    my @files = qw( t/text/ );

    for my $context ( undef, '-A', '-B', '-C' ) {
        my @args = qw( \s$ );

        push( @args, $context ) if $context;

        ack_sets_match( [ @args, @files ], \@expected, '\s$ should not match the newlines at the end of a line' );
    }
};

subtest 'whitespace+dollar with -l' => sub {
    plan tests => 1;

    my @expected = ();

    my @files = qw( t/text/ );
    my @args = qw( \s$ -l );

    ack_sets_match( [ @args, @files ], \@expected, '\s$ should not match the newlines at the end of a line' );
};

subtest 'whitespace+dollar with -L' => sub {
    plan tests => 1;

    my @expected = line_split( <<'HERE' );
t/text/amontillado.txt
t/text/bill-of-rights.txt
t/text/constitution.txt
t/text/gettysburg.txt
t/text/number.txt
t/text/numbered-text.txt
t/text/ozymandias.txt
t/text/raven.txt
HERE

    my @files = qw( t/text/ );
    my @args = qw( \s$ -L --sort );

    ack_sets_match( [ @args, @files ], \@expected, '\s$ should not match the newlines at the end of a line' );
};

subtest 'whitespace+dollar with -v' => sub {
    plan tests => 4;

    my @expected = line_split( <<'HERE' );
I met a traveller from an antique land
Who said: Two vast and trunkless legs of stone
Stand in the desert... Near them, on the sand,
Half sunk, a shattered visage lies, whose frown,
And wrinkled lip, and sneer of cold command,
Tell that its sculptor well those passions read
Which yet survive, stamped on these lifeless things,
The hand that mocked them, and the heart that fed:
And on the pedestal these words appear:
'My name is Ozymandias, king of kings:
Look on my works, ye Mighty, and despair!'
Nothing beside remains. Round the decay
Of that colossal wreck, boundless and bare
The lone and level sands stretch far away.
HERE

    my @files = qw( t/text/ozymandias.txt );

    for my $context ( undef, '-A', '-B', '-C' ) {
        my @args = qw( \s$ -v );

        push( @args, $context ) if $context;

        ack_sets_match( [ @args, @files ], \@expected, '\s$ should not match the newlines at the end of a line' );
    }
};

done_testing();
exit 0;
