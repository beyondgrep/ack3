#!perl

use warnings;
use strict;

use Test::More tests => 20;

use lib 't';
use Util;

prep_environment();

subtest 'No starting directory specified' => sub {
    plan tests => 3;

    my $regex = 'non';

    my @files = qw( t/foo/non-existent );
    my @args = ( '-g', $regex );
    my ($stdout, $stderr) = run_ack_with_stderr( @args, @files );

    is_empty_array( $stdout, 'No STDOUT for non-existent file' );
    is( scalar @{$stderr}, 1, 'One line of STDERR for non-existent file' );
    like( $stderr->[0], qr/non-existent: No such file or directory/,
        'Correct warning message for non-existent file' );
};


subtest 'regex comes before -g on the command line' => sub {
    plan tests => 3;

    my $regex = 'non';

    my @files = qw( t/foo/non-existent );
    my @args = ( $regex, '-g' );
    my ($stdout, $stderr) = run_ack_with_stderr( @args, @files );

    is_empty_array( $stdout, 'No STDOUT for non-existent file' );
    is( scalar @{$stderr}, 1, 'One line of STDERR for non-existent file' );
    like( $stderr->[0], qr/non-existent: No such file or directory/,
        'Correct warning message for non-existent file' );
};


subtest 'No metacharacters' => sub {
    plan tests => 1;

    my @expected = qw(
        t/swamp/Makefile
        t/swamp/Makefile.PL
        t/swamp/notaMakefile
    );
    my $regex = 'Makefile';

    my @args  = ( '-g', $regex );
    my @files = qw( t/ );

    ack_sets_match( [ @args, @files ], \@expected, "Looking for $regex" );
};


subtest 'With metacharacters' => sub {
    plan tests => 1;

    my @expected = qw(
        t/swamp/html.htm
        t/swamp/html.html
    );
    my $regex = 'swam.......htm';

    my @args  = ( '-g', $regex );
    my @files = qw( t/ );

    ack_sets_match( [ @args, @files ], \@expected, "Looking for $regex" );
};


subtest 'Front anchor' => sub {
    plan tests => 1;

    my @expected = qw(
        t/swamp/c-header.h
        t/swamp/c-source.c
        t/swamp/constitution-100k.pl
        t/swamp/crystallography-weenies.f
    );
    my $regex = '^t.swamp.c';

    my @args  = ( '-g', $regex );
    my @files = qw( t/swamp );

    ack_sets_match( [ @args, @files ], \@expected, "Looking for $regex" );
};


subtest 'Back anchor' => sub {
    plan tests => 1;

    my @expected = qw(
        t/swamp/constitution-100k.pl
        t/swamp/options-crlf.pl
        t/swamp/options.pl
        t/swamp/perl.pl
    );
    my $regex = 'pl$';

    my @args  = ( '-g', $regex );
    my @files = qw( t/swamp );

    ack_sets_match( [ @args, @files ], \@expected, "Looking for $regex" );
};


subtest 'Case-insensitive via -i' => sub {
    plan tests => 1;

    my @expected = qw(
        t/swamp/pipe-stress-freaks.F
    );
    my $regex = 'PIPE';

    my @args  = ( '-i', '-g', $regex );
    my @files = qw( t/swamp );

    ack_sets_match( [ @args, @files ], \@expected, "Looking for -i -g $regex " );
};


subtest 'Case-insensitive via (?i:)' => sub {
    plan tests => 1;

    my @expected = qw(
        t/swamp/pipe-stress-freaks.F
    );
    my $regex = '(?i:PIPE)';

    my @files = qw( t/swamp );
    my @args  = ( '-g', $regex );

    ack_sets_match( [ @args, @files ], \@expected, "Looking for $regex" );
};


subtest 'Negate -i via -I' => sub {
    plan tests => 1;

    my @expected = qw();
    my $regex = 'PIPE';

    my @args = ( '-i', '-I', '-g', $regex);
    my @files = qw( t/swamp );

    ack_sets_match( [ @args, @files ], \@expected, "Looking for -i -I -g $regex" );
};


subtest 'Negate -I via -i' => sub {
    plan tests => 1;

    my @expected = qw(
        t/swamp/pipe-stress-freaks.F
    );
    my $regex = 'PIPE';

    my @args  = ( '-I', '-i', '-g', $regex );
    my @files = qw( t/swamp );

    ack_sets_match( [ @args, @files ], \@expected, "Looking for -I -i -g $regex " );

};


subtest 'File on command line is always searched' => sub {
    plan tests => 1;

    my @expected = ( 't/swamp/#emacs-workfile.pl#' );
    my $regex = 'emacs';

    my @args = ( '-g', $regex );
    my @files = ( 't/swamp/#emacs-workfile.pl#' );

    ack_sets_match( [ @args, @files ], \@expected, 'File on command line is always searched' );
};


subtest 'File on command line is always searched, even with wrong filetype' => sub {
    plan tests => 1;

    my @expected = qw(
        t/swamp/notes.md
    );
    my @files = qw( t/swamp/notes.md );
    my @args  = qw( -t html -g notes );

    ack_sets_match( [ @args, @files ], \@expected, 'File on command line is always searched, even with wrong type.' );
};


subtest '-Q works on -g' => sub {
    plan tests => 2;

    # Matches without the -Q
    my @expected = qw( t/swamp/file.bar );
    my $regex = 'file.bar$';

    my @files = qw( t );
    my @args  = ( '-g', $regex );

    ack_sets_match( [ @args, @files ], \@expected, "Looking for $regex without -Q." );

    # Doesn't match with -Q.
    ack_sets_match( [ @args, '-Q', @files ], [], "Looking for $regex with -Q." );
};


subtest '-w works on -g' => sub {
    plan tests => 1;

    my @expected = qw(
        t/text/number.txt
    );
    my $regex = 'number';  # "number" shouldn't match "numbered"

    my @files = qw( t/text );
    my @args  = ( '-w', '-g', $regex, '--sort-files' );

    ack_sets_match( [ @args, @files ], \@expected, "Looking for $regex with '-w'." );
};


subtest '-v works on -g' => sub {
    plan tests => 1;

    my @expected = qw(
        t/text/bill-of-rights.txt
        t/text/gettysburg.txt
    );
    my $file_regex = 'n';

    my @args  = ( '-v', '-g', $file_regex, '--sort-files' );
    my @files = qw( t/text/ );

    ack_sets_match( [ @args, @files ], \@expected, "Looking for file names that do not match $file_regex" );
};


subtest '--smart-case works on -g' => sub {
    plan tests => 2;

    my @expected = qw(
        t/swamp/pipe-stress-freaks.F
        t/swamp/crystallography-weenies.f
    );

    my @files = qw( t/swamp );
    my @args  = ( '--smart-case', '-g', 'f$' );

    ack_sets_match( [ @args, @files ], \@expected, 'Looking for f$' );

    @expected = qw(
        t/swamp/pipe-stress-freaks.F
    );
    @args = ( '-S', '-g', 'F$' );

    ack_sets_match( [ @args, @files ], \@expected, 'Looking for f$' );
};


subtest 'test exit codes' => sub {
    plan tests => 4;

    my $file_regex = 'foo';
    my @files      = ( 't/text/' );

    run_ack( '-g', $file_regex, @files );
    is( get_rc(), 1, '-g with no matches must exit with 1' );

    $file_regex = 'raven';

    run_ack( '-g', $file_regex, @files );
    is( get_rc(), 0, '-g with matches must exit with 0' );
};


subtest 'test -g on a path' => sub {
    plan tests => 1;

    my $file_regex = 'text';
    my @expected   = qw(
        t/text/amontillado.txt
        t/text/bill-of-rights.txt
        t/text/constitution.txt
        t/text/gettysburg.txt
        t/text/number.txt
        t/text/numbered-text.txt
        t/text/ozymandias.txt
        t/text/raven.txt
    );
    my @args = ( '--sort-files', '-g', $file_regex, 't/text' );

    ack_sets_match( [ @args ], \@expected, 'Make sure -g matches the whole path' );
};


subtest 'test -g with --color' => sub {
    plan tests => 2;

    my $file_regex = 'text';
    my $expected_original = <<'HERE';
t/(text)/amontillado.txt
t/(text)/bill-of-rights.txt
t/(text)/constitution.txt
t/(text)/gettysburg.txt
t/(text)/number.txt
t/(text)/numbered-(text).txt
t/(text)/ozymandias.txt
t/(text)/raven.txt
HERE

    $expected_original = windows_slashify( $expected_original ) if is_windows;

    my @expected   = colorize( $expected_original );

    my @args = ( '--sort-files', '-g', $file_regex );

    my @results = run_ack(@args, '--color', 't/text');

    is_deeply( \@results, \@expected, 'Colorizing -g output with --color should work');
};


subtest q{test -g without --color; make sure colors don't show} => sub {
    if ( !has_io_pty() ) {
        plan skip_all => 'IO::Pty is required for this test';
        return;
    }

    plan tests => 1;

    my $file_regex = 'text';
    my $expected   = <<'HERE';
t/text/amontillado.txt
t/text/bill-of-rights.txt
t/text/constitution.txt
t/text/gettysburg.txt
t/text/number.txt
t/text/numbered-text.txt
t/text/ozymandias.txt
t/text/raven.txt
HERE

    my @args = ( '--sort-files', '-g', $file_regex, 't/text' );

    my $results = run_ack_interactive(@args);

    is( $results, $expected, 'Colorizing -g output without --color should have no color' );
};

done_testing();

exit 0;
