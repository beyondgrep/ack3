#!perl

# https://github.com/beyondgrep/ack3/issues/192

use strict;
use warnings;

use Test::More tests => 5;
use lib 't';
use Util;

prep_environment();


my ( $stdout, $stderr ) = run_ack_with_stderr( '--bloofga' );
is_empty_array( $stdout, 'No output because of our bad option' );

is( $stderr->[0], 'Unknown option: bloofga', 'First line is the error, and should only appear once' );
like( $stderr->[1], qr/ack(?:-standalone)?: Invalid option on command line/, 'Second line is the general error' );
is( scalar @{$stderr}, 2, 'There are no more lines' );

is( get_rc(), 255, 'Should fail' );

exit 0;
