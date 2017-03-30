#!perl -T

use strict;
use warnings;
use lib 't';

use Test::More tests => 2;
use Util;

prep_environment();


my $tempfile = create_tempfile( ('') x 3 );

my @results = run_ack('^\s\s+$', $tempfile->filename);

lists_match(\@results, [], '^\s\s+$ should never match a sequence of empty lines');

done_testing();

exit 0;
