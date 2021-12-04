#!perl

use strict;
use warnings;

use Test::More tests => 8;

use lib 't';
use Util;

prep_environment();

INTERACTIVE_MULTIPLE_FILES: {
    my @args = qw( --no-lineno --no-color strict );
    my @files = qw( t/swamp/options.pl t/swamp/pipe-stress-freaks.F );

    my $target_file = reslash( 't/swamp/options.pl' );
    my @expected = line_split( <<"HERE" );
$target_file
use strict;
HERE

    my @results = run_ack_interactive( @args, @files );

    lists_match( \@results, \@expected, 'Looking for strict interactively in multiple files' );
}

INTERACTIVE_MULTIPLE_FILES_NO_HEADING: {
    my @args = qw( --no-lineno --no-heading --no-color strict );
    my @files = qw( t/swamp/options.pl t/swamp/pipe-stress-freaks.F );

    my $target_file = reslash( 't/swamp/options.pl' );
    my @expected = line_split( <<"HERE" );
$target_file:use strict;
HERE

    my @results = run_ack_interactive( @args, @files );

    lists_match( \@results, \@expected, 'Looking for strict interactively in multiple files with --no-heading' );
}

INTERACTIVE_ONE_FILE: {
    my @args = ( qw( --no-lineno --with-filename --no-color strict ) );
    my @files = qw( t/swamp/options.pl );

    my $target_file = reslash( 't/swamp/options.pl' );
    my @expected = line_split( <<"HERE" );
$target_file
use strict;
HERE

    my @results = run_ack_interactive( @args, @files );

    lists_match( \@results, \@expected, 'Looking for strict interactively in one file with filename' );
}

INTERACTIVE_ONE_FILE_NO_HEADING: {
    my @args = ( qw( --no-lineno --with-filename --no-heading --no-color strict ) );
    my @files = qw( t/swamp/options.pl );

    my $target_file = reslash( 't/swamp/options.pl' );
    my @expected = line_split( <<"HERE" );
$target_file:use strict;
HERE

    my @results = run_ack_interactive( @args, @files );

    lists_match( \@results, \@expected, 'Looking for strict interactively in one file with filename and --no-heading' );
}

NON_INTERACTIVE_MULTIPLE_FILES: {
    my @args = qw( --no-lineno strict );
    my @files = qw( t/swamp/options.pl t/swamp/pipe-stress-freaks.F );

    my $target_file = reslash( 't/swamp/options.pl' );
    my @expected = line_split( <<"HERE" );
$target_file:use strict;
HERE

    my @results = run_ack( @args, @files );

    lists_match( \@results, \@expected, 'Looking for strict in multiple files' );
}

NON_INTERACTIVE_ONE_FILE: {
    my @args = ( qw( --no-lineno --with-filename strict ) );
    my @files = qw( t/swamp/options.pl );

    my $target_file = reslash( 't/swamp/options.pl' );
    my @expected = line_split( <<"HERE" );
$target_file:use strict;
HERE

    my @results = run_ack( @args, @files );

    lists_match( \@results, \@expected, 'Looking for strict in one file with filename' );
}

done_testing();

exit 0;
