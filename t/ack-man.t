#!perl

use strict;
use warnings;
use 5.010001;

use lib 't';
use Util;

use Test::More;

plan tests => 3;

prep_environment();

my ($stdout, $stderr) = run_ack_with_stderr( '--man' );

cmp_ok( scalar @{$stdout}, '>', 900, 'The manual should be pretty long.' );
cmp_ok( scalar @{$stdout}, '<', 2000, 'But not too long.' );

my $filtered_stderr = filter_out_perldoc_noise( $stderr );
is_empty_array( $filtered_stderr, 'Nothing in STDERR' );

done_testing();

exit 0;
