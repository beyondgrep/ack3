#!perl

use warnings;
use strict;

use Test::More tests => 8;

use lib 't';
use Util;
use Barfly;

prep_environment();

# Run some basic tests.
Barfly->run_tests( 't/ack-underline.barfly' );

# Most of the rest of this file is done manually rather than in Barfly
# because Barfly relies on --underline working correctly.

my $bill_ = reslash( 't/text/bill-of-rights.txt' );
my $getty = reslash( 't/text/gettysburg.txt' );

# Spacing that the filenames take up.
my $spc_b = ' ' x length( $bill_ );
my $spc_g = ' ' x length( $getty );


subtest 'Single file' => sub {
    plan tests => 1;

    my @expected = line_split( <<'HERE' );
A well regulated Militia, being necessary to the security of a free State,
                 ^^^^^^^
cases arising in the land or naval forces, or in the Militia, when in
                                                     ^^^^^^^
HERE

    my @files = $bill_;
    my @args  = ( qw( --underline ), 'Militia' );

    ack_lists_match( [ @args, @files ], \@expected, 'Single file' );
};


subtest 'Grouped' => sub {
    plan tests => 1;

    my @expected = line_split( <<"HERE" );
$bill_
10:A well regulated Militia, being necessary to the security of a free State,
                    ^^^^^^^
31:cases arising in the land or naval forces, or in the Militia, when in
                                                        ^^^^^^^
HERE

    my @files = qw( t/text/bill-of-rights.txt t/text/ozymandias.txt ); # Don't want Constitution in here.
    my @args  = ( qw( --underline --group ), 'Militia' );

    ack_lists_match( [ @args, @files ], \@expected, 'Grouped' );
};


subtest 'Not grouped, with leading filename' => sub {
    my @expected = line_split( <<"HERE" );
$bill_:10:A well regulated Militia, being necessary to the security of a free State,
$spc_b                     ^^^^^^^
$bill_:31:cases arising in the land or naval forces, or in the Militia, when in
$spc_b                                                         ^^^^^^^
HERE

    my $regex = 'Militia';
    my @files = $bill_;
    my @args  = ( qw( --underline --nogroup -H ), $regex );

    ack_lists_match( [ @args, @files ], \@expected, "Looking for $regex - before with line numbers" );
};

subtest 'Grouped --underline' => sub {
    plan tests => 1;

    my @expected = line_split( <<"HERE" );
$bill_
4:or prohibiting the free exercise thereof; or abridging the freedom of
                                                             ^^^^^^^

$getty
23:shall have a new birth of freedom -- and that government of the people,
                             ^^^^^^^
HERE

    my @args = qw( --underline --sort-files --group freedom t/text );

    ack_lists_match( [ @args ], \@expected, 'Looking for freedom, grouped' );
};


subtest 'Ungrouped --underline' => sub {
    plan tests => 1;

    my @expected = line_split( <<"HERE" );
$bill_:4:or prohibiting the free exercise thereof; or abridging the freedom of
$spc_b                                                              ^^^^^^^
$getty:23:shall have a new birth of freedom -- and that government of the people,
$spc_g                              ^^^^^^^
HERE

    my @args = qw( --underline --sort-files --nogroup freedom t/text );

    ack_lists_match( [ @args ], \@expected, 'Looking for freedom, ungrouped' );
};


subtest 'Grouped --underline with context' => sub {
    plan tests => 1;

    my @expected = line_split( <<"HERE" );
$bill_
2-
3-Congress shall make no law respecting an establishment of religion,
4:or prohibiting the free exercise thereof; or abridging the freedom of
                                                             ^^^^^^^
5-speech, or of the press; or the right of the people peaceably to assemble,
6-and to petition the Government for a redress of grievances.

$getty
21-the last full measure of devotion -- that we here highly resolve that
22-these dead shall not have died in vain -- that this nation, under God,
23:shall have a new birth of freedom -- and that government of the people,
                             ^^^^^^^
24-by the people, for the people, shall not perish from the earth.
HERE

    my @args = qw( --underline --sort-files --group -C free\w+ t/text );

    ack_lists_match( [ @args ], \@expected, 'Looking for freedom, grouped with context' );
};


subtest 'Ungrouped --underline with --context' => sub {
    plan tests => 1;

    my @expected = line_split( <<"HERE" );
$bill_-2-
$bill_-3-Congress shall make no law respecting an establishment of religion,
$bill_:4:or prohibiting the free exercise thereof; or abridging the freedom of
$spc_b                                                              ^^^^^^^
$bill_-5-speech, or of the press; or the right of the people peaceably to assemble,
$bill_-6-and to petition the Government for a redress of grievances.
--
$getty-21-the last full measure of devotion -- that we here highly resolve that
$getty-22-these dead shall not have died in vain -- that this nation, under God,
$getty:23:shall have a new birth of freedom -- and that government of the people,
$spc_g                              ^^^^^^^
$getty-24-by the people, for the people, shall not perish from the earth.
HERE

    my @args = qw( --underline --sort-files --nogroup -C free\w+ t/text );

    ack_lists_match( [ @args ], \@expected, 'Looking for freedom, ungrouped' );
};

exit 0;
