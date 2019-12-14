#!perl

use warnings;
use strict;

use Test::More tests => 15;

use lib 't';
use Util;
use Barfly;

prep_environment();

my $ACK = $ENV{ACK_TEST_STANDALONE} ? 'ack-standalone' : 'ack';

Barfly->run_tests( 't/ack-w.barfly' );

subtest '-w with trailing metachar \w' => sub {
    plan tests => 1;

    my @expected = line_split( <<'HERE' );
A well regulated Militia, being necessary to the security of a free State,
cases arising in the land or naval forces, or in the Militia, when in
HERE

    my @files = qw( t/text/bill-of-rights.txt );
    my @args = ( 'Milit\w\w', qw( -w -h --sort-files ) );

    ack_lists_match( [ @args, @files ], \@expected, 'Looking for militia with metacharacters' );
};


subtest '-w with trailing dot' => sub {
    plan tests => 1;

    my @expected = line_split( <<'HERE' );
A well regulated Militia, being necessary to the security of a free State,
cases arising in the land or naval forces, or in the Militia, when in
HERE

    my @files = qw( t/text/bill-of-rights.txt );
    my @args = ( 'Milit..', qw( -w -h --sort-files ) );

    ack_lists_match( [ @args, @files ], \@expected, 'Looking for Milit..' );
};


subtest 'Begins and ends with word char' => sub {
    plan tests => 1;

    # Normal case of whole word match.
    my @expected = line_split( <<'HERE' );
A well regulated Militia, being necessary to the security of a free State,
cases arising in the land or naval forces, or in the Militia, when in
HERE

    my @files = qw( t/text/bill-of-rights.txt );
    my @args = qw( Militia -w -h --sort-files );

    ack_lists_match( [ @args, @files ], \@expected, 'Looking for Militia as whole word' );
};


subtest 'Ends with grouping parens' => sub {
    plan tests => 1;

    # The last character of the regexp is not a word, disabling the word boundary check at the end of the match.
    my @expected = line_split( <<'HERE' );
A well regulated Militia, being necessary to the security of a free State,
cases arising in the land or naval forces, or in the Militia, when in
HERE

    my @files = qw( t/text/bill-of-rights.txt );
    my @args = ( 'Militia()', qw( -w -h --sort-files ) );

    ack_lists_match( [ @args, @files ], \@expected, 'Looking for Militia with word flag, but regexp does not end with word char' );
};


subtest 'Begins with grouping parens' => sub {
    plan tests => 1;

    my @expected = line_split( <<'HERE' );
A well regulated Militia, being necessary to the security of a free State,
cases arising in the land or naval forces, or in the Militia, when in
HERE

    my @files = qw( t/text/bill-of-rights.txt );
    my @args = ( '()Militia', qw( -w -h --sort-files ) );

    ack_lists_match( [ @args, @files ], \@expected, 'Looking for Militia with word flag, but regexp does not begin with word char' );
};


subtest 'Wrapped in grouping parens' => sub {
    plan tests => 1;

    my @expected = line_split( <<'HERE' );
A well regulated Militia, being necessary to the security of a free State,
cases arising in the land or naval forces, or in the Militia, when in
HERE

    my @files = qw( t/text/bill-of-rights.txt );
    my @args = ( '(Militia)', qw( -w -h --sort-files ) );

    ack_lists_match( [ @args, @files ], \@expected, 'Looking for Militia with word flag, but regexp does not begin or end with word char' );
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
    my ($good,$bad,$inv) = _get_good_and_bad();

    plan tests => @{$good} + @{$bad} + @{$inv};

    my $happy = reslash( 't/text/ozymandias.txt' );
    for my $pattern ( @{$good} ) {
        subtest "Good example: $pattern" => sub {
            plan tests => 1;

            my ( undef, $stderr ) = run_ack_with_stderr( $pattern, '-w', $happy );
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
            like( $stderr->[0], qr/$ACK: -w will not do the right thing/, 'Got the correct warning' );
        };
    }

    for my $pattern ( @{$inv} ) {
        subtest "Invalid regex: $pattern" => sub {
            plan tests => 3;

            # Add the -- because the pattern may have hyphens.
            my ( $stdout, $stderr ) = run_ack_with_stderr( '-w', '--', $pattern, $happy );
            is_empty_array( $stdout, 'Should have no output' );
            is( scalar @{$stderr}, 3, 'One warning' );
            like( $stderr->[0], qr/$ACK: Invalid regex '\Q$pattern'/ );
        };
    }
};


sub _get_good_and_bad {
    # BAD = should throw a warning with -w
    # OK  = should not throw a warning with -w
    # INV = is an invalid regex whether with -w or not
    my @examples = line_split( <<'HERE' );
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
INV )start with closing paren
INV end with opening paren(
BAD end with an escaped closing paren\)

# Character classes
OK  [sg]et
OK  foo[lt]
OK  [one big character class]
OK  [multiple][character][classes]
BAD ]starting with a closing bracket
INV ending with an opening bracket[
BAD ending with an escaped closing bracket \]

# Quantifiers
OK  thpppt{1,5}
BAD }starting with an closing curly brace
BAD ending with an escaped closing curly brace\}

OK  foo+
BAD foo\+
INV +foo
OK  foo*
BAD foo\*
INV *foo
OK  foo?
BAD foo\?
INV ?foo

# Miscellaneous debris
BAD -foo
BAD foo-
BAD &mpersand
BAD ampersand&
INV function(
BAD ->method
BAD <header.h>
BAD =14
BAD /slashes/
BAD ::Class::Whatever
BAD Class::Whatever::
OK  Class::Whatever

HERE

    my $good = [];
    my $bad  = [];
    my $inv  = [];

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
        elsif ( $line =~ /INV\s+(.+)/ ) {
            push( @{$inv}, $1 );
        }
        else {
            die "Invalid line: $line";
        }
    }

    return ($good, $bad, $inv);
}

done_testing();

exit 0;
