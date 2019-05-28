#!perl -T

use strict;
use warnings;

use Test::More tests => 2;
use lib 't';
use Util;

use App::Ack;

prep_environment();

my ( $stdout, $stderr ) = run_ack_with_stderr( '--version' );

my $ack_ver = sprintf( 'v%vd', $App::Ack::VERSION );
is_empty_array( $stderr, 'Nothing in stderr' );
my @lines = @{$stdout};
like( $lines[0], qr/\Q$ack_ver/, 'Found the version in the first line' );

done_testing();

exit 0;
