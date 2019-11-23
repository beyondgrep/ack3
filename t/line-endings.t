#!perl

=pod

This test checks for problems where line endings aren't handled correctly
by our pre-scanning of the file.

    # https://github.com/beyondgrep/ack2/issues/491
    v2.14 with "-l" not emitting all matching files.

    > echo ' ' >space-newline.txt
    > echo $' \n' >space-newline-newline.txt
    > ack ' $' space-newline*.txt
    space-newline-newline.txt
    1:

    space-newline.txt
    1:
    > ack -l ' $' space-newline*.txt
    space-newline.txt

=cut

use strict;
use warnings;
use lib 't';

use Test::More tests => 4;
use File::Temp;
use Util;

prep_environment();

my $dir = File::Temp->newdir;
my $wd  = getcwd_clean();

safe_chdir( $dir->dirname );

my %matching_files = (
    'space-newline.txt'          => " \n",
    'space-newline-space.txt'    => " \n\t",
    'space-newline-newline.txt'  => " \n\n",
    'space-newline-and-more.txt' => "this\n \nthat\n",
    'words-and-spaces.txt'       => "this \nand that\n",
);
my %nonmatching_files = (
    'tabby.txt'      => "\t\n",
    'also-tabby.txt' => " \t\n",
);

my %all_files = ( %matching_files, %nonmatching_files );
while ( my ($file,$content) = each %all_files ) {
    write_file( $file, $content );
}
my @all_files         = keys %all_files;
my @matching_files    = keys %matching_files;
my @nonmatching_files = keys %nonmatching_files;

subtest 'Match normally' => sub {
    plan tests => 2;

    my @results = run_ack( ' $', @all_files );
    my @files_matched = @results;
    s/:.*// for @files_matched;
    sets_match( \@files_matched, [ @matching_files ], 'Found all the matching files in results' );
};

subtest 'Match with -l' => sub {
    plan tests => 2;

    my @results = run_ack( '-l', ' $', @all_files );
    sets_match( \@results, [ @matching_files ], 'Matching files should be in -l output' );
};

subtest 'Non-match with -L' => sub {
    plan tests => 2;

    my @results = run_ack( '-L', ' $', @all_files );
    sets_match( \@results, [ @nonmatching_files ], 'Nonmatching files should be in -L output' );
};

subtest 'Count with -c' => sub {
    plan tests => 2;

    my @results = run_ack( '-c', ' $', @all_files );
    sets_match( \@results, [
        map { "$_:" . ( $matching_files{$_} ? 1 : 0 ) } @all_files
    ], 'Matching files should be in -c output with correct counts' );
};

safe_chdir( $wd );  # Get out of temp directory so it can be cleaned up.

done_testing();
exit 0;
