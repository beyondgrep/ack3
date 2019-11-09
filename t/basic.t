#!perl

use strict;
use warnings;
use lib 't';

use Util;
use Test::More tests => 14;

prep_environment();


NO_SWITCHES_ONE_DIRECTORY: {
    my $target_file = reslash( 't/text/gettysburg.txt' );
    my @expected = line_split( <<"HERE" );
$target_file:14:struggled here, have consecrated it, far above our poor power to add or
HERE

    my @files = qw( t/text );
    my @args = qw( consecrated );
    my @results = run_ack( @args, @files );

    lists_match( \@results, \@expected, 'Looking for strict in one directory' );
}


NO_SWITCHES_ONE_FILE: {
    my @expected = line_split( <<'HERE' );
use strict;
HERE

    my @files = qw( t/swamp/options.pl );
    my @args = qw( strict );
    my @results = run_ack( @args, @files );

    lists_match( \@results, \@expected, 'Looking for strict in one file' );
}


NO_SWITCHES_MULTIPLE_FILES: {
    my $options_file = reslash( 't/swamp/options.pl' );
    my $const___file = reslash( 't/text/constitution.txt' );
    my @expected = line_split( <<"HERE" );
$const___file:225:such District (not exceeding ten Miles square) as may, by Cession of
$options_file:2:use strict;
HERE

    my @files = qw( t/text/constitution.txt t/swamp/pipe-stress-freaks.F t/swamp/options.pl );
    my @args = qw( strict );
    my @results = run_ack( @args, @files );

    lists_match( \@results, \@expected, 'Looking for strict in multiple files' );
}


WITH_SWITCHES_ONE_FILE: {
    my $target_file = reslash( 't/swamp/options.pl' );
    for my $opt ( qw( -H --with-filename ) ) {
        my @expected = line_split( <<"HERE" );
$target_file:2:use strict;
HERE

        my @files = qw( t/swamp/options.pl );
        my @args = ( $opt, qw( strict ) );
        my @results = run_ack( @args, @files );

        lists_match( \@results, \@expected, "Looking for strict in one file with $opt" );
    }
}


WITH_SWITCHES_MULTIPLE_FILES: {
    for my $opt ( qw( -h --no-filename ) ) {
        my @expected = line_split( <<"HERE" );
use strict;
HERE

        my @files = qw( t/swamp/options.pl t/swamp/crystallography-weenies.f );
        my @args = ( $opt, qw( strict ) );
        my @results = run_ack( @args, @files );

        lists_match( \@results, \@expected, "Looking for strict in multiple files with $opt" );
    }
}

done_testing();
exit 0;
