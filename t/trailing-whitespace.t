#!perl -T

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

    my @expected = line_split( <<'EOF' );
t/text/4th-of-july.txt
t/text/boy-named-sue.txt
t/text/freedom-of-choice.txt
t/text/me-and-bobbie-mcgee.txt
t/text/number.txt
t/text/numbered-text.txt
t/text/science-of-myth.txt
t/text/shut-up-be-happy.txt
EOF

    my @files = qw( t/text/ );
    my @args = qw( \s$ -L --sort );

    ack_sets_match( [ @args, @files ], \@expected, '\s$ should not match the newlines at the end of a line' );
};

subtest 'whitespace+dollar with -v' => sub {
    plan tests => 4;

    my @expected = line_split( <<'EOF' );
If you've ever questioned beliefs that you've hold, you're not alone
But you oughta realize that every myth is a metaphor
In the case of Christianity and Judaism there exists the belief
That spiritual matters are enslaved to history

The Buddhists believe that the functional aspects override the myth
While other religions use the literal core to build foundations with
See, half the world sees the myth as fact, and it's seen as a lie by the other half
And the simple truth is that it's none of that 'cause
Somehow no matter what the world keeps turning
Somehow we get by without ever learning

Science and religion are not mutually exclusive
In fact, for better understanding we take the facts of science and apply them
And if both factors keep evolving then we continue getting information
But closing off the possibilities makes it hard to see the bigger picture

Consider the case of the woman whose faith helped her make it through
When she was raped and cut up, left for dead in her trunk, her beliefs held true
It doesn't matter if it's real or not
'cause some things are better left without a doubt
And if it works, then it gets the job done
Somehow no matter what the world keeps turning
Somehow we get by without ever learning

    -- "The Science Of Myth", Screeching Weasel
EOF

    my @files = qw( t/text/science-of-myth.txt );

    for my $context ( undef, '-A', '-B', '-C' ) {
        my @args = qw( \s$ -v );

        push( @args, $context ) if $context;

        ack_sets_match( [ @args, @files ], \@expected, '\s$ should not match the newlines at the end of a line' );
    }
};

done_testing();
exit 0;
