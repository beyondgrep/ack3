#!perl

use strict;
use warnings;

use Test::More;
use lib 't';
use Util;

plan tests => 1;

prep_environment();

subtest 'Check diags' => sub {
    my ($output,$stderr) = run_ack_with_stderr( 'foo(bar' );

    my @expected = line_split( <<'HERE' );
ack: Invalid regex 'foo(bar'
Regex: foo(bar
          ^---HERE Unmatched ( in regex
HERE
    is_empty_array( $output, 'No output' );
    lists_match( $stderr, \@expected, 'Error body' );
};


exit 0;
