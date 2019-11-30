#!perl

use warnings;
use strict;

use Test::More tests => 2;

use lib 't';
use Util;

prep_environment();

NORMAL_CASE: {
    my @expected = line_split( <<'END' );
I met a traveller from an antique land
Stand in the desert... Near them, on the sand,
Which yet survive, stamped on these lifeless things,
The hand that mocked them, and the heart that fed:
'My name is Ozymandias, king of kings:
Nothing beside remains. Round the decay
END

    my @args  = qw( -v w );
    my @files = qw( t/text/ozymandias.txt );

    ack_lists_match( [ @args, @files ], \@expected, 'Find the lines that do not contain a "w"' );
}

IGNORE_CASE: {
    my @expected = line_split( <<'END' );
I met a traveller from an antique land
Stand in the desert... Near them, on the sand,
The hand that mocked them, and the heart that fed:
'My name is Ozymandias, king of kings:
Nothing beside remains. Round the decay
END

    my @args  = qw( -i -v w );
    my @files = qw( t/text/ozymandias.txt );

    ack_lists_match( [ @args, @files ], \@expected, 'Find the lines that do not contain a "w", ignoring case' );
}

done_testing();

exit 0;
