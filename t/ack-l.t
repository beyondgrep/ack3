#!perl

use strict;
use warnings;

use Test::More;

plan tests => 4;

use lib 't';
use Util;

prep_environment();


my @matching = qw(
    t/text/bill-of-rights.txt
    t/text/constitution.txt
);

my @nonmatching = qw(
    t/text/amontillado.txt
    t/text/gettysburg.txt
    t/text/number.txt
    t/text/numbered-text.txt
    t/text/ozymandias.txt
    t/text/raven.txt
);

for my $arg ( qw( -l --files-with-matches ) ) {
    subtest "Files with matches: $arg" => sub {
        my @results = run_ack( $arg, 'strict', 't/text' );
        sets_match( \@results, \@matching, 'File list match' );
    }
};


for my $arg ( qw( -L --files-without-matches ) ) {
    subtest "Files without matches: $arg" => sub {
        my @results = run_ack( $arg, 'strict', 't/text' );
        sets_match( \@results, \@nonmatching, 'File list match' );
    }
};

exit 0;
