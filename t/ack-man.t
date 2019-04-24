#!perl -T

use strict;
use warnings;
use 5.010001;

use lib 't';
use Util;

use Test::More;

plan tests => 1;

prep_environment();

my ($stdout, $stderr) = run_ack_with_stderr( '--man' );

my $filtered_stderr = filter_out_perldoc_noise( $stderr );
is_empty_array( $filtered_stderr, 'Nothing in STDERR' );

done_testing();

exit 0;
