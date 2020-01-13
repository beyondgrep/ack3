#!perl

use strict;
use warnings;

use Test::More;

plan tests => 3;

use lib 't';
use Util;

prep_environment();

my $ACK = $ENV{ACK_TEST_STANDALONE} ? 'ack-standalone' : 'ack';

# The unquoted "+" in "svn+ssh" will make the match fail.

subtest 'Plus sign' => sub {
    plan tests => 3;

    my @args = qw( svn+ssh t/swamp );
    ack_lists_match( [ @args ], [], 'No matches without the -Q' );

    my $target = reslash( 't/swamp/Rakefile' );
    my @expected = line_split( <<"HERE" );
$target:44:  baseurl = "svn+ssh:/#{ENV['USER']}\@rubyforge.org/var/svn/#{PKG_NAME}"
$target:50:  baseurl = "svn+ssh:/#{ENV['USER']}\@rubyforge.org/var/svn/#{PKG_NAME}"
HERE
    for my $arg ( qw( -Q --literal ) ) {
        ack_lists_match( [ @args, $arg ], \@expected, "$arg should make svn+ssh finable" );
    }
};


subtest 'Square brackets' => sub {
    plan tests => 4;

    my @args = qw( [ack] t/swamp );
    my @results = run_ack( @args );
    cmp_ok( scalar @results, '>', 100, 'Without quoting, the [ack] returns many matches' );

    my $target = reslash( 't/swamp/Makefile' );
    my @expected = line_split( <<"HERE" );
$target:15:#     EXE_FILES => [q[ack]]
$target:17:#     NAME => q[ack]
HERE
    for my $arg ( qw( -Q --literal ) ) {
        ack_lists_match( [ @args, $arg ], \@expected, "$arg should make svn+ssh finable" );
    }
};


subtest 'Patterns that would be invalid if not -Q' => sub {
    plan tests => 21;

    my %problems = (
        '*' => 'Quantifier follows nothing in regex',
        '[' => 'Unmatched [ in regex',
        '(' => 'Unmatched ( in regex',
    );

    while ( my ($problem, $explanation) = each %problems ) {
        my ($output,$stderr) = run_ack_with_stderr( $problem );

        is_empty_array( $output, 'No output' );
        is( $stderr->[0], "$ACK: Invalid regex '$problem'", 'Line 1 OK' );
        is( $stderr->[1], "Regex: $problem", 'Line 2 OK' );
        like( $stderr->[2], qr/\Q^---HERE $explanation/, 'Does the explanation match?' );
        is( scalar @{$stderr}, 3, 'Only 3 lines' );
    }

    for my $problem ( keys %problems ) {
        my @results = run_ack( '-Q', $problem );
        cmp_ok( scalar @results, '>', 100, 'When we quote, all is happy and we get lots of results' );
    }
};


exit 0;
