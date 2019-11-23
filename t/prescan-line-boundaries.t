#!perl

# https://github.com/beyondgrep/ack2/issues/571

use strict;
use warnings;
use lib 't';

use Test::More tests => 2;
use Util;

prep_environment();

my $tempfile = create_tempfile( <<'HERE' );
fo

oo
HERE

my @results = run_ack('-l', 'fo\s+oo', $tempfile->filename);
is_empty_array( \@results, '\s+ should never match across line boundaries' );
