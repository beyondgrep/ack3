#!perl -T

use strict;
use warnings;
use lib 't';

use Test::More tests => 2;
use Util;

prep_environment();

my $tempfile = create_tempfile( <<'END_OF_FILE' );
fo

oo
END_OF_FILE

my @results = run_ack('-l', 'fo\s+oo', $tempfile->filename);
is_empty_array( \@results, '\s+ should never match across line boundaries' );
