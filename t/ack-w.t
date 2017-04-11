#!perl -T

use warnings;
use strict;

use Test::More tests => 14;

use lib 't';
use Util;
use Barfly;

prep_environment();

Barfly->run_tests( 't/ack-w.barfly' );


subtest '-w with trailing metachar \w' => sub {
    plan tests => 1;

    my @expected = line_split( <<'EOF' );
At an old saloon on a street of mud,
Kicking and a-gouging in the mud and the blood and the beer.
EOF

    my @files = qw( t/text );
    my @args = qw( mu\w -w -h --sort-files );

    ack_lists_match( [ @args, @files ], \@expected, 'Looking for mu\\w' );
};


subtest '-w with trailing dot' => sub {
    plan tests => 1;

    my @expected = line_split( <<'EOF' );
At an old saloon on a street of mud,
Kicking and a-gouging in the mud and the blood and the beer.
EOF

    my @files = qw( t/text );
    my @args = ( 'mu.', qw( -w -h --sort-files ) );

    ack_lists_match( [ @args, @files ], \@expected, 'Looking for mu.' );
};


subtest 'Begins and ends with word char' => sub {
    plan tests => 1;

    # Normal case of whole word match.
    my @expected = line_split( <<'EOF' );
And I said: "My name is Sue! How do you do! Now you gonna die!"
To kill me now, and I wouldn't blame you if you do.
EOF

    my @files = qw( t/text );
    my @args = ( 'do', qw( -w -h --sort-files ) );

    ack_lists_match( [ @args, @files ], \@expected, 'Looking for do as whole word' );
};


subtest 'Ends with grouping parens' => sub {
    plan tests => 1;

    # The last character of the regexp is not a word, disabling the word boundary check at the end of the match.
    my @expected = (
        'Took us all the way to New Orleans',
    );

    my @files = qw( t/text );
    my @args = ( 'us()', qw( -w -h --sort-files ) );

    ack_lists_match( [ @args, @files ], \@expected, 'Looking for us with word flag, but regexp does not end with word char' );
};


subtest 'Begins with grouping parens' => sub {
    plan tests => 1;

    my @expected = line_split( <<'EOF' );
If you ain't got no one
He said: "Now you just fought one hell of a fight
He picked at one
He picked at one
But I'd trade all of my tomorrows for one single yesterday
The number one enemy of progress is questions.
EOF

    my @files = qw( t/text );
    my @args = ( '()one', qw( -w -h --sort-files ) );

    ack_lists_match( [ @args, @files ], \@expected, 'Looking for one with word flag, but regexp does not begin with word char' );
};


subtest 'Wrapped in grouping parens' => sub {
    plan tests => 1;

    my @expected = (
        'Consider the case of the woman whose faith helped her make it through',
        'When she was raped and cut up, left for dead in her trunk, her beliefs held true'
    );

    my @files = qw( t/text/science-of-myth.txt );
    my @args = ( '(her)', qw( -w -h --sort-files ) );

    ack_lists_match( [ @args, @files ], \@expected, 'Looking for her with word flag, but regexp does not begin or end with word char' );
};


# Test for issue ack2#443
subtest 'Alternating numbers' => sub {
    plan tests => 1;

    my @expected = ();

    my @files = qw( t/text/number.txt );

    my @args = ( '650|660|670|680', '-w' );

    ack_lists_match( [ @args, @files ], \@expected, 'Alternations should also respect boundaries when using -w' );
};

done_testing();

exit 0;
