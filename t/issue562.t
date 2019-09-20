#!perl

# https://github.com/beyondgrep/ack2/issues/562

use strict;
use warnings;
use lib 't';

use Test::More tests => 2;
use Util;

prep_environment();


my $tempfile = create_tempfile( ('') x 3 );

my @results = run_ack('^\s\s+$', $tempfile->filename);

is_empty_array( \@results, '^\s\s+$ should never match a sequence of empty lines' );

done_testing();

exit 0;
