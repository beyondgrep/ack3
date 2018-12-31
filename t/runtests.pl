#! /usr/bin/perl
#---------------------------------------------------------------------
# Run tests for ack
#
# Windows makes it hard to temporarily set environment variables, and
# has horrible quoting rules, so what should be a one-liner gets its
# own script.
#---------------------------------------------------------------------

use ExtUtils::Command::MM;

$ENV{PERL_DL_NONLAZY} = 1;
$ENV{ACK_TEST_STANDALONE} = shift;

defined($ENV{ACK_TEST_STANDALONE}) or die 'Must pass an argument to set ACK_TEST_STANDALONE';

# Make sure the tests' standard input is *never* a pipe (messes with ack's filter detection).
open STDIN, '<', '/dev/null';

printf(
    "Running tests on %s, ACK_TEST_STANDALONE=%s\n",
    $ENV{ACK_TEST_STANDALONE} ? 'ack-standalone' : 'blib/script/ack',
    $ENV{ACK_TEST_STANDALONE}
);
test_harness(shift, shift, shift);
