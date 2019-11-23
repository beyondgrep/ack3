#!perl

# Multiple capture groups used to confuse ack.
# https://github.com/beyondgrep/ack2/issues/244

use strict;
use warnings;
use Test::More;

use lib 't';
use Util;

plan tests => 2;

prep_environment();

my ( $stdout, $stderr ) = run_ack_with_stderr('--color', '(foo)|(bar)', 't/swamp');
is_nonempty_array( $stdout );
is_empty_array( $stderr );

exit 0;
