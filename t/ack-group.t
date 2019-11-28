#!perl

use strict;
use warnings;

use Test::More;

use lib 't';
use Util;

if ( not has_io_pty() ) {
    plan skip_all => q{You need to install IO::Pty to run this test};
    exit(0);
}

plan tests => 8;

prep_environment();

my ($bill_, $const, $getty) = map { reslash( "t/text/$_" ) } qw( bill-of-rights.txt constitution.txt gettysburg.txt );

my @TEXT_FILES = sort map { untaint($_) } glob( 't/text/*.txt' );


NO_GROUPING: {
    my @expected = line_split( <<"HERE" );
$bill_:4:or prohibiting the free exercise thereof; or abridging the freedom of
$bill_:10:A well regulated Militia, being necessary to the security of a free State,
$const:32:Number of free Persons, including those bound to Service for a Term
$getty:23:shall have a new birth of freedom -- and that government of the people,
HERE

    my @cases = (
        [qw( --nogroup --nocolor free )],
        [qw( --nobreak --noheading --nocolor free )],
    );
    for my $args ( @cases ) {
        my @results = run_ack_interactive( @{$args}, @TEXT_FILES );
        lists_match( \@results, \@expected, 'No grouping' );
    }
}


STANDARD_GROUPING: {
    my @expected = line_split( <<"HERE" );
$bill_
4:or prohibiting the free exercise thereof; or abridging the freedom of
10:A well regulated Militia, being necessary to the security of a free State,

$const
32:Number of free Persons, including those bound to Service for a Term

$getty
23:shall have a new birth of freedom -- and that government of the people,
HERE

    my @cases = (
        [qw( --group --nocolor free )],
        [qw( --heading --break --nocolor free )],
    );
    for my $args ( @cases ) {
        my @results = run_ack_interactive( @{$args}, @TEXT_FILES );
        lists_match( \@results, \@expected, 'Standard grouping' );
    }
}

HEADING_NO_BREAK: {
    my @expected = line_split( <<"HERE" );
$bill_
4:or prohibiting the free exercise thereof; or abridging the freedom of
10:A well regulated Militia, being necessary to the security of a free State,
$const
32:Number of free Persons, including those bound to Service for a Term
$getty
23:shall have a new birth of freedom -- and that government of the people,
HERE

    my @arg_sets = (
        [qw( --heading --nobreak --nocolor free )],
        [qw( --nobreak --nocolor free )],
    );
    for my $set ( @arg_sets ) {
        my @results = run_ack_interactive( @{$set}, @TEXT_FILES );
        lists_match( \@results, \@expected, 'Heading, no break' );
    }
}

BREAK_NO_HEADING: {
    my @expected = line_split( <<"HERE" );
$bill_:4:or prohibiting the free exercise thereof; or abridging the freedom of
$bill_:10:A well regulated Militia, being necessary to the security of a free State,

$const:32:Number of free Persons, including those bound to Service for a Term

$getty:23:shall have a new birth of freedom -- and that government of the people,
HERE

    my @arg_sets = (
        [qw( --break --noheading --nocolor free )],
        [qw( --noheading --nocolor free )],
    );
    for my $set ( @arg_sets ) {
        my @results = run_ack_interactive( @{$set}, @TEXT_FILES );
        lists_match( \@results, \@expected, 'Break, no heading' );
    }
}

done_testing();
exit 0;
