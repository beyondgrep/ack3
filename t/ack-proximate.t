#!perl

use warnings;
use strict;

use Test::More tests => 7;

use lib 't';
use Util;

prep_environment();

my $const = reslash( 't/text/constitution.txt' );
my $bill  = reslash( 't/text/bill-of-rights.txt' );

subtest 'Grouped proximate' => sub {
    plan tests => 2;

    my @expected = line_split( <<"HERE" );
$bill
53:fact tried by a jury, shall be otherwise re-examined in any Court of

$const
199:To constitute Tribunals inferior to the supreme Court;

372:Judges of the supreme Court, and all other Officers of the United States,

376:in the Courts of Law, or in the Heads of Departments.

404:Court, and in such inferior Courts as the Congress may from time to

406:Courts, shall hold their Offices during good Behaviour, and shall, at

425:and those in which a State shall be Party, the supreme Court shall

427:the supreme Court shall have appellate Jurisdiction, both as to Law and

441:of two Witnesses to the same overt Act, or on Confession in open Court.
HERE

    my @files = qw( t/text );
    my @args = qw( -p -i --group --sort court );

    for my $arg ( qw( --proximate -p ) ) {
        $args[0] = $arg;
        ack_lists_match( [ @args, @files ], \@expected, 'Grouped proximate' );
    }
};


subtest 'Ungrouped proximate' => sub {
    plan tests => 2;

    my @expected = line_split( <<"HERE" );
$bill:53:fact tried by a jury, shall be otherwise re-examined in any Court of

$const:199:To constitute Tribunals inferior to the supreme Court;

$const:372:Judges of the supreme Court, and all other Officers of the United States,

$const:376:in the Courts of Law, or in the Heads of Departments.

$const:404:Court, and in such inferior Courts as the Congress may from time to

$const:406:Courts, shall hold their Offices during good Behaviour, and shall, at

$const:425:and those in which a State shall be Party, the supreme Court shall

$const:427:the supreme Court shall have appellate Jurisdiction, both as to Law and

$const:441:of two Witnesses to the same overt Act, or on Confession in open Court.
HERE

    my @files = qw( t/text );
    my @args = qw( --proximate -i --nogroup --sort court );

    for my $arg ( qw( --proximate -p ) ) {
        $args[0] = $arg;
        ack_lists_match( [ @args, @files ], \@expected, 'Ungrouped proximate' );
    }
};


subtest 'Grouped proximate=2' => sub {
    plan tests => 2;

    my @expected = line_split( <<"HERE" );
$bill
53:fact tried by a jury, shall be otherwise re-examined in any Court of

$const
199:To constitute Tribunals inferior to the supreme Court;

372:Judges of the supreme Court, and all other Officers of the United States,

376:in the Courts of Law, or in the Heads of Departments.

404:Court, and in such inferior Courts as the Congress may from time to
406:Courts, shall hold their Offices during good Behaviour, and shall, at

425:and those in which a State shall be Party, the supreme Court shall
427:the supreme Court shall have appellate Jurisdiction, both as to Law and

441:of two Witnesses to the same overt Act, or on Confession in open Court.
HERE

    my @files = qw( t/text );
    my @args = qw( --proximate=2 --group -i --sort court );

    for my $arg ( qw( --proximate=2 -p2 ) ) {
        $args[0] = $arg;
        ack_lists_match( [ @args, @files ], \@expected, 'Grouped proximate=2' );
    }
};


subtest 'Grouped proximate=2 with --not' => sub {
    plan tests => 2;

    my @expected = line_split( <<"HERE" );
$bill
53:fact tried by a jury, shall be otherwise re-examined in any Court of

$const
199:To constitute Tribunals inferior to the supreme Court;

372:Judges of the supreme Court, and all other Officers of the United States,

404:Court, and in such inferior Courts as the Congress may from time to
406:Courts, shall hold their Offices during good Behaviour, and shall, at

425:and those in which a State shall be Party, the supreme Court shall

441:of two Witnesses to the same overt Act, or on Confession in open Court.
HERE

    my @files = qw( t/text );
    my @args = qw( --proximate=2 --group -i --sort court --not law );

    for my $arg ( qw( --proximate=2 -p2 ) ) {
        $args[0] = $arg;
        ack_lists_match( [ @args, @files ], \@expected, 'Grouped proximate=2' );
    }
};




subtest 'Ungrouped proximate=2' => sub {
    plan tests => 2;

    my @expected = line_split( <<"HERE" );
$bill:53:fact tried by a jury, shall be otherwise re-examined in any Court of

$const:199:To constitute Tribunals inferior to the supreme Court;

$const:372:Judges of the supreme Court, and all other Officers of the United States,

$const:376:in the Courts of Law, or in the Heads of Departments.

$const:404:Court, and in such inferior Courts as the Congress may from time to
$const:406:Courts, shall hold their Offices during good Behaviour, and shall, at

$const:425:and those in which a State shall be Party, the supreme Court shall
$const:427:the supreme Court shall have appellate Jurisdiction, both as to Law and

$const:441:of two Witnesses to the same overt Act, or on Confession in open Court.
HERE

    my @files = qw( t/text );
    my @args = qw( --proximate=2 --nogroup -i --sort court );

    for my $arg ( qw( --proximate=2 -p2 ) ) {
        $args[0] = $arg;
        ack_lists_match( [ @args, @files ], \@expected, 'Ungrouped proximate=2' );
    }
};



subtest 'Ungrouped proximate=20' => sub {
    plan tests => 2;

    my @expected = line_split( <<"HERE" );
$bill:53:fact tried by a jury, shall be otherwise re-examined in any Court of

$const:199:To constitute Tribunals inferior to the supreme Court;

$const:372:Judges of the supreme Court, and all other Officers of the United States,
$const:376:in the Courts of Law, or in the Heads of Departments.

$const:404:Court, and in such inferior Courts as the Congress may from time to
$const:406:Courts, shall hold their Offices during good Behaviour, and shall, at
$const:425:and those in which a State shall be Party, the supreme Court shall
$const:427:the supreme Court shall have appellate Jurisdiction, both as to Law and
$const:441:of two Witnesses to the same overt Act, or on Confession in open Court.
HERE

    my @files = qw( t/text );
    my @args = qw( --proximate=20 --nogroup -i --sort court );

    for my $arg ( qw( --proximate=20 -p20 ) ) {
        $args[0] = $arg;
        ack_lists_match( [ @args, @files ], \@expected, 'Ungrouped proximate=20' );
    }
};


subtest '-P overrides --prox' => sub {
    plan tests => 1;

    my @expected = line_split( <<"HERE" );
$bill:53:fact tried by a jury, shall be otherwise re-examined in any Court of
$const:199:To constitute Tribunals inferior to the supreme Court;
$const:372:Judges of the supreme Court, and all other Officers of the United States,
$const:376:in the Courts of Law, or in the Heads of Departments.
$const:404:Court, and in such inferior Courts as the Congress may from time to
$const:406:Courts, shall hold their Offices during good Behaviour, and shall, at
$const:425:and those in which a State shall be Party, the supreme Court shall
$const:427:the supreme Court shall have appellate Jurisdiction, both as to Law and
$const:441:of two Witnesses to the same overt Act, or on Confession in open Court.
HERE

    my @files = qw( t/text );
    my @args = qw( --proximate=20 --nogroup -i --sort -P court );

    ack_lists_match( [ @args, @files ], \@expected, '-P overrides --prox' );
};

done_testing();

exit 0;
