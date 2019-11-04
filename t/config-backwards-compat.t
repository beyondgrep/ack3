#!perl

use strict;
use warnings;

use lib 't';
use Util;
use Test::More tests => 3;

prep_environment();

my $temp_config = create_tempfile( <<'HERE' );
# Always sort
--sort-files

# I'm tired of grouping
--noheading
--break

# Handle .hwd files
--type-set=hwd=.hwd

# Handle .md files
--type-set=md=.mkd
--type-add=md=.md

# Handle .textile files
--type-set=textile=.textile

# Hooray for smart-case!
--smart-case

--ignore-dir=nytprof
HERE

my @args = ( '--ackrc=' . $temp_config->filename, '-t', 'md', 'One', 't/swamp/' );

my $file = reslash('t/swamp/notes.md');
my $line = 3;

my ( $stdout, $stderr ) = run_ack_with_stderr( @args );
is( scalar(@{$stdout}), 1, 'Got back exactly one line' );
like $stdout->[0], qr/\Q$file:$line\E.*[*] One/;
is_empty_array( $stderr, 'No output to stderr' );
