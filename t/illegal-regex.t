#!perl

use strict;
use warnings;

use Test::More;
use lib 't';
use Util;

plan tests => 2;

prep_environment();

my $ACK = $ENV{ACK_TEST_STANDALONE} ? 'ack-standalone' : 'ack';

# This unmatched paren is fatal.
subtest 'Check fatal' => sub {
    plan tests => 2;

    my ($output,$stderr) = run_ack_with_stderr( '(set|get)_user_(id|(username)' );

    my @expected = line_split( <<"HERE" );
$ACK: Invalid regex '(set|get)_user_(id|(username)'
Regex: (set|get)_user_(id|(username)
                      ^---HERE Unmatched ( in regex
HERE
    is_empty_array( $output, 'No output' );
    lists_match( $stderr, \@expected, 'Error body' );
};

# In Perl 5.20 and below, opening brace at the end doesn't get a warning.
# In Perl 5.22 and above, we get a warning but the text changes.
# This opening brace at the end is just a warning, but we still catch it in Perl > 5.20.
subtest 'Check warning' => sub {
    if ( $^V < 5.022 ) {
        return pass( "Perl $^V does not throw a warning on the closing brace" );
    }

    plan tests => 5;

    my ($output,$stderr) = run_ack_with_stderr( 'foo{' );

    is_empty_array( $output, 'No output' );
    is( $stderr->[0], "$ACK: Invalid regex 'foo{'", 'Line 1 OK' );
    is( $stderr->[1], 'Regex: foo{', 'Line 2 OK' );
    like( $stderr->[2], qr/\Q^---HERE Unescaped left brace/, 'The message changes between Perl versions' );
    is( scalar @{$stderr}, 3, 'Only 3 lines' );
};


exit 0;
