#!perl

use strict;
use warnings;
use lib 't';

use Test::More tests => 6;

use Util;

prep_environment();


my @textfiles = qw(
    t/text/amontillado.txt
    t/text/bill-of-rights.txt
    t/text/constitution.txt
    t/text/gettysburg.txt
    t/text/ozymandias.txt
    t/text/raven.txt
);


subtest 'Basic reading from files, no switches' => sub {
    plan tests => 1;

    my $target_file = reslash( 't/swamp/options.pl' );
    my @expected = line_split( <<"HERE" );
$target_file:2:use strict;
HERE

    my $tempfile = create_tempfile( qw( t/swamp/options.pl t/swamp/pipe-stress-freaks.F ) );

    ack_lists_match( [ '--files-from=' . $tempfile->filename, 'strict' ], \@expected, 'Looking for strict in multiple files' );

    unlink $tempfile->filename;
};


subtest 'Non-existent file specified' => sub {
    plan tests => 3;

    my @args = qw( strict );
    my ( $stdout, $stderr ) = run_ack_with_stderr( '--files-from=non-existent-file', @args);

    is_empty_array( $stdout, 'No STDOUT for non-existent file' );
    is( scalar @{$stderr}, 1, 'One line of STDERR for non-existent file' );
    like( $stderr->[0], qr/Unable to open non-existent-file:/,
        'Correct warning message for non-existent file' );
};


subtest 'Source file exists, but non-existent files mentioned in the file' => sub {
    plan tests => 4;

    my $tempfile = create_tempfile( qw( t/swamp/options.pl file-that-isnt-there ) );
    my ( $stdout, $stderr ) = run_ack_with_stderr( '--files-from=' . $tempfile->filename, 'CASE');

    is( scalar @{$stdout}, 1, 'One hit found' );
    like( $stdout->[0], qr/THIS IS ALL IN UPPER CASE/, 'Find the one line in the file' );

    is( scalar @{$stderr}, 1, 'One line of STDERR for non-existent file' );
    like( $stderr->[0], qr/file-that-isnt-there: No such file/, 'Correct warning message for non-existent file' );
};


subtest '-l and --files-from' => sub {
    plan tests => 1;

    my $tempfile = create_tempfile( @textfiles );

    my @expected = qw(
        t/text/amontillado.txt
        t/text/gettysburg.txt
        t/text/raven.txt
    );

    ack_sets_match( [ '--files-from=' . $tempfile->filename, 'God', '-l' ], \@expected, 'Looking for God files' );
};


subtest '-L and --files-from' => sub {
    plan tests => 1;

    my $tempfile = create_tempfile( @textfiles );

    my @expected = qw(
        t/text/bill-of-rights.txt
        t/text/constitution.txt
        t/text/ozymandias.txt
    );

    ack_sets_match( [ '--files-from=' . $tempfile->filename, 'God', '-L' ], \@expected, 'Looking for absence of God' );
};


subtest '-c and --files-from' => sub {
    plan tests => 1;

    my $tempfile = create_tempfile( @textfiles );

    my @expected = qw(
        t/text/amontillado.txt:2
        t/text/bill-of-rights.txt:0
        t/text/constitution.txt:0
        t/text/gettysburg.txt:1
        t/text/ozymandias.txt:0
        t/text/raven.txt:2
    );

    ack_sets_match( [ '--files-from=' . $tempfile->filename, 'God', '-c' ], \@expected, 'Looking for God files' );
};


done_testing();

exit 0;
