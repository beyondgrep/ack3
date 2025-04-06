#!perl

use warnings;
use strict;

use Test::More tests => 5;

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


subtest 'test -g with --color' => sub {
    plan tests => 2;

    my $file_regex = 'text';
    my $expected_original = <<'HERE';
t/(text)/amontillado.txt
t/(text)/bill-of-rights.txt
t/(text)/constitution.txt
t/(text)/gettysburg.txt
t/(text)/movies.txt
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
t/text/movies.txt
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
