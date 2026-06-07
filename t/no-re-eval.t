#!perl

use 5.010;
use strict;
use warnings;

use Test::More tests => 1;

use File::Spec ();
use File::Temp ();

use lib 't';
use Util;

prep_environment();

# Global:
# /tmp/x/etc/.ackrc
# /tmp/x/swamp

my $wd = getcwd_clean();

_test_re_eval();

exit 0;

# Test project directory
# ackrc in /tmp/x/project/.ackrc
sub _test_re_eval {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    return subtest subtest_name() => sub {
        plan tests => 5;

        # Code assertions are normally permitted in compiled Perl but not runtime JIT qr// or match// substitutions.
        # -M re=eval enables runtime eval-group (?{code}) (??{code}) (*{code}) in runtime qr//.
        # This is unsafe given $PROJECT/.ackrc --type, --ignore options, so it's blocked
        #
        # TODO Could add tests for --ignore --match --and REs, etc etc, as of several files prefaced by `no re 'eval';`
        # this actually monitors only one for regression.
        #
        $ENV{ACK_TEST_MODULE_OPTS}='re=eval'; ## Evil to be thwarted, ask Util.pm to prefix evil -Mre=eval for us

        my ( $stdout, $stderr ) = run_ack_with_stderr('-f',
            q(--type-add=badtype:firstlinematch:/(?{print "hello executing code \n"})oops/), ## code injection
            '--badtype', 't/swamp');

        is_empty_array( $stdout, 'No output with the errors' );  # If not fixed, will say 'hello executing code ' repeatedly.

        is(scalar(@$stderr), 3, 'number of errors as expected' );
        like($stderr->[0], qr/\QEval-group not allowed at runtime,\E/, "Eval-group blocked in type RE" );
        like($stderr->[1], qr/\QUnknown option: badtype\E/, "Unknown option in type RE" );
        like($stderr->[2], qr/\QInvalid option on command line\E/, "invalid option reported" );
    }
};
