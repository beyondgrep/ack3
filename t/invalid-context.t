#!perl

use 5.010;
use strict;
use warnings;

use Test::More tests => 5;
use lib 't';
use Util;

prep_environment();


my ( $stdout, $stderr ) = run_ack_with_stderr( '-C20000' );
is_empty_array( $stdout, 'No output because of our bad option' );

like( $stderr->[0], qr/ack(?:-standalone)?: Context value 20000 exceeds the maximum allowed value of 10000[.]/, 'First line is the specific error' );
like( $stderr->[1], qr/ack(?:-standalone)?: Invalid option on command line/, 'Second line is the general error' );
is( scalar @{$stderr}, 2, 'There are no more lines' );

is( get_rc(), 255, 'Should fail' );

exit 0;
