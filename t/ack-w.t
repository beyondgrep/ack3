#!perl -T

use warnings;
use strict;

use Test::More tests => 23;

use lib 't';
use Util;
use Barfly;

prep_environment();

Barfly->run_tests( 't/ack-w.barfly' );

TRAILING_PUNC: {
    my @expected = (
        'And I said: "My name is Sue! How do you do! Now you gonna die!"',
        'Bill or George! Anything but Sue! I still hate that name!',
    );

    my @files = qw( t/text );
    my @args = qw( Sue! -w -h --sort-files );

    ack_lists_match( [ @args, @files ], \@expected, 'Looking for Sue!' );
}

TRAILING_METACHAR_BACKSLASH_W: {
    my @expected = (
        'At an old saloon on a street of mud,',
        'Kicking and a-gouging in the mud and the blood and the beer.',
    );

    my @files = qw( t/text );
    my @args = qw( mu\w -w -h --sort-files );

    ack_lists_match( [ @args, @files ], \@expected, 'Looking for mu\\w' );
}


TRAILING_METACHAR_DOT: {
    # Because the . at the end of the regular expression is not a word
    # character, a word boundary is not required after the match.
    my @expected = (
        'At an old saloon on a street of mud,',
        'Kicking and a-gouging in the mud and the blood and the beer.',
    );

    my @files = qw( t/text );
    my @args = ( 'mu.', qw( -w -h --sort-files ) );

    ack_lists_match( [ @args, @files ], \@expected, 'Looking for mu.' );
}

BEGINS_AND_ENDS_WITH_WORD_CHAR: {
    # Normal case of whole word match.
    my @expected = (
      'And I said: "My name is Sue! How do you do! Now you gonna die!"',
      "To kill me now, and I wouldn't blame you if you do.",
    );

    my @files = qw( t/text );
    my @args = ( 'do', qw( -w -h --sort-files ) );

    ack_lists_match( [ @args, @files ], \@expected, 'Looking for do as whole word' );
}

BEGINS_BUT_NOT_ENDS_WITH_WORD_CHAR: {
    # The last character of the regexp is not a word, disabling the word boundary check at the end of the match.
    my @expected = (
        'Took us all the way to New Orleans',
    );

    my @files = qw( t/text );
    my @args = ( 'us()', qw( -w -h --sort-files ) );

    ack_lists_match( [ @args, @files ], \@expected, 'Looking for us with word flag, but regexp does not end with word char' );
}

ENDS_BUT_NOT_BEGINS_WITH_WORD_CHAR: {
    # The first character of the regexp is not a word, disabling the word boundary check at the start of the match.
    my @expected = (
        'If you ain\'t got no one',
        'He said: "Now you just fought one hell of a fight',
        'He picked at one',
        'He picked at one',
        'But I\'d trade all of my tomorrows for one single yesterday',
        'The number one enemy of progress is questions.',
    );

    my @files = qw( t/text );
    my @args = ( '()one', qw( -w -h --sort-files ) );

    ack_lists_match( [ @args, @files ], \@expected, 'Looking for one with word flag, but regexp does not begin with word char' );
}

NEITHER_BEGINS_NOR_ENDS_WITH_WORD_CHAR: {
    # Because the regular expression doesn't begin or end with a word character, the 'words mode' doesn't affect the match.
    my @expected = (
        'Consider the case of the woman whose faith helped her make it through',
        'When she was raped and cut up, left for dead in her trunk, her beliefs held true'
    );

    my @files = qw( t/text/science-of-myth.txt );
    my @args = ( '(her)', qw( -w -h --sort-files ) );

    ack_lists_match( [ @args, @files ], \@expected, 'Looking for her with word flag, but regexp does not begin or end with word char' );
}

# Test for issue #443
ALTERNATING_NUMBERS: {
    my @expected = ();

    my @files = qw( t/text/number.txt );

    my @args = ( '650|660|670|680', '-w' );

    ack_lists_match( [ @args, @files ], \@expected, 'Alternations should also respect boundaries when using -w' );
}

done_testing();

exit 0;
