#!perl

use strict;
use warnings;

use Test::More tests => 2;
use lib 't';
use Util;

use App::Ack;

prep_environment();

my ( $stdout, $stderr ) = run_ack_with_stderr( '--version' );

is_empty_array( $stderr, 'Nothing in stderr' );
my @lines = @{$stdout};
like( $lines[0], qr/\Q$App::Ack::VERSION/, 'Found the version in the first line' );

done_testing();

exit 0;
