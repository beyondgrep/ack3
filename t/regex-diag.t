#!perl

use strict;
use warnings;

use Test::More;
use lib 't';
use Util;

plan tests => 1;

prep_environment();

my $ACK = $ENV{ACK_TEST_STANDALONE} ? 'ack-standalone' : 'ack';

subtest 'Check diags' => sub {
    my ($output,$stderr) = run_ack_with_stderr( '(set|get)_user_(id|(username)' );

    my @expected = line_split( <<"HERE" );
$ACK: Invalid regex '(set|get)_user_(id|(username)'
Regex: (set|get)_user_(id|(username)
                      ^---HERE Unmatched ( in regex
HERE
    is_empty_array( $output, 'No output' );
    lists_match( $stderr, \@expected, 'Error body' );
};


subtest 'Curly brace' => sub {
    my ($output,$stderr) = run_ack_with_stderr( 'End with opening curly brace {' );

    my @expected = line_split( <<"HERE" );
$ACK: Invalid regex 'End with opening curly brace {'
Regex: End with opening curly brace {
                                    ^---HERE Unmatched ( in regex
HERE
    is_empty_array( $output, 'No output' );
    lists_match( $stderr, \@expected, 'Error body' );
};


exit 0;
