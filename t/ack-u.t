#!perl -T

use warnings;
use strict;

use Test::More tests => 1;

use lib 't';
use Util;
use Barfly;

prep_environment();

Barfly->run_tests( 't/ack-u.barfly' );

done_testing();

exit 0;
