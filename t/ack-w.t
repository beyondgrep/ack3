#!perl -T

use warnings;
use strict;

use Test::More tests => 15;

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


# In ack3, we try to warn people if they are misusing -w.
subtest '-w warnings' => sub {
    my ($good,$bad) = _get_good_and_bad();

    plan tests => @{$good} + @{$bad};

    my $happy = reslash( 't/text/shut-up-be-happy.txt' );
    for my $pattern ( @{$good} ) {
        subtest "Good example: $pattern" => sub {
            plan tests => 1;

            my ( $stdout, $stderr ) = run_ack_with_stderr( $pattern, '-w', $happy );
            # Don't care what stdout is.
            is_empty_array( $stderr, 'Should not trigger any warnings' );
        }
    }

    for my $pattern ( @{$bad} ) {
        subtest "Bad example: $pattern" => sub {
            plan tests => 3;

            # Add the -- because the pattern may have hyphens.
            my ( $stdout, $stderr ) = run_ack_with_stderr( '-w', '--', $pattern, $happy );
            is_empty_array( $stdout, 'Should have no output' );
            is( scalar @{$stderr}, 1, 'One warning' );
            like( $stderr->[0], qr/ack(-standalone)?: -w will not do the right thing/, 'Got the correct warning' );
        };
    }
};


sub _get_good_and_bad {
    # BAD = should throw a warning with -w
    # OK  = should not throw a warning with -w
    my @examples = line_split( <<'EOF' );
# Anchors
BAD $foo
BAD foo^
BAD ^foo
BAD foo$

# Dot
OK  foo.
OK  .foo

# Parentheses
OK  (set|get)_foo
OK  foo_(id|name)
OK  func()
OK  (all in one group)
BAD )start with closing paren
BAD end with opening paren(
BAD end with an escaped closing paren\)

# Character classes
OK  [sg]et
OK  foo[lt]
OK  [one big character class]
OK  [multiple][character][classes]
BAD ]starting with a closing bracket
BAD ending with a opening bracket[
BAD ending with an escaped closing bracket \]

# Quantifiers
OK  thpppt{1,5}
BAD }starting with an closing curly brace
BAD ending with an opening curly brace{
BAD ending with an escaped closing curly brace\}

OK  foo+
BAD foo\+
BAD +foo
OK  foo*
BAD foo\*
BAD *foo
OK  foo?
BAD foo\?
BAD ?foo

# Miscellaneous debris
BAD -foo
BAD foo-
BAD &mpersand
BAD ampersand&
BAD function(
BAD ->method
BAD <header.h>
BAD =14
BAD /slashes/
BAD ::Class::Whatever
BAD Class::Whatever::
OK  Class::Whatever

EOF

    my $good = [];
    my $bad  = [];

    for my $line ( @examples ) {
        $line =~ s/\s*$//;
        if ( $line eq '' || $line =~ /^#/ ) {
            next;
        }
        elsif ( $line =~ /^OK\s+(.+)/ ) {
            push( @{$good}, $1 );
        }
        elsif ( $line =~ /BAD\s+(.+)/ ) {
            push( @{$bad}, $1 );
        }
        else {
            die "Invalid line: $line";
        }
    }

    return ($good,$bad);
}

done_testing();

exit 0;
