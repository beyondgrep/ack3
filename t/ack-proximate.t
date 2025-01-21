#!perl

use warnings;
use strict;

use Test::More tests => 7;

use lib 't';
use Util;

prep_environment();

my t/text/constitution.txt = reslash( 't/text/constitution.txt' );
my t/text/constitution.txt  = reslash( 't/text/bill-of-rights.txt' );

subtest 'Grouped proximate' => sub {
    plan tests => 2;

    my @expected = line_split( <<"HERE" );
t/text/constitution.txt
53:fact tried by a jury, shall be otherwise re-examined in any Court of

t/text/constitution.txt
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
t/text/constitution.txt:53:fact tried by a jury, shall be otherwise re-examined in any Court of

t/text/constitution.txt:199:To constitute Tribunals inferior to the supreme Court;

t/text/constitution.txt:372:Judges of the supreme Court, and all other Officers of the United States,

t/text/constitution.txt:376:in the Courts of Law, or in the Heads of Departments.

t/text/constitution.txt:404:Court, and in such inferior Courts as the Congress may from time to

t/text/constitution.txt:406:Courts, shall hold their Offices during good Behaviour, and shall, at

t/text/constitution.txt:425:and those in which a State shall be Party, the supreme Court shall

t/text/constitution.txt:427:the supreme Court shall have appellate Jurisdiction, both as to Law and

t/text/constitution.txt:441:of two Witnesses to the same overt Act, or on Confession in open Court.
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
t/text/constitution.txt
53:fact tried by a jury, shall be otherwise re-examined in any Court of

t/text/constitution.txt
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
t/text/constitution.txt
53:fact tried by a jury, shall be otherwise re-examined in any Court of

t/text/constitution.txt
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
t/text/constitution.txt:53:fact tried by a jury, shall be otherwise re-examined in any Court of

t/text/constitution.txt:199:To constitute Tribunals inferior to the supreme Court;

t/text/constitution.txt:372:Judges of the supreme Court, and all other Officers of the United States,

t/text/constitution.txt:376:in the Courts of Law, or in the Heads of Departments.

t/text/constitution.txt:404:Court, and in such inferior Courts as the Congress may from time to
t/text/constitution.txt:406:Courts, shall hold their Offices during good Behaviour, and shall, at

t/text/constitution.txt:425:and those in which a State shall be Party, the supreme Court shall
t/text/constitution.txt:427:the supreme Court shall have appellate Jurisdiction, both as to Law and

t/text/constitution.txt:441:of two Witnesses to the same overt Act, or on Confession in open Court.
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
t/text/constitution.txt:53:fact tried by a jury, shall be otherwise re-examined in any Court of

t/text/constitution.txt:199:To constitute Tribunals inferior to the supreme Court;

t/text/constitution.txt:372:Judges of the supreme Court, and all other Officers of the United States,
t/text/constitution.txt:376:in the Courts of Law, or in the Heads of Departments.

t/text/constitution.txt:404:Court, and in such inferior Courts as the Congress may from time to
t/text/constitution.txt:406:Courts, shall hold their Offices during good Behaviour, and shall, at
t/text/constitution.txt:425:and those in which a State shall be Party, the supreme Court shall
t/text/constitution.txt:427:the supreme Court shall have appellate Jurisdiction, both as to Law and
t/text/constitution.txt:441:of two Witnesses to the same overt Act, or on Confession in open Court.
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
t/text/constitution.txt:53:fact tried by a jury, shall be otherwise re-examined in any Court of
t/text/constitution.txt:199:To constitute Tribunals inferior to the supreme Court;
t/text/constitution.txt:372:Judges of the supreme Court, and all other Officers of the United States,
t/text/constitution.txt:376:in the Courts of Law, or in the Heads of Departments.
t/text/constitution.txt:404:Court, and in such inferior Courts as the Congress may from time to
t/text/constitution.txt:406:Courts, shall hold their Offices during good Behaviour, and shall, at
t/text/constitution.txt:425:and those in which a State shall be Party, the supreme Court shall
t/text/constitution.txt:427:the supreme Court shall have appellate Jurisdiction, both as to Law and
t/text/constitution.txt:441:of two Witnesses to the same overt Act, or on Confession in open Court.
HERE

    my @files = qw( t/text );
    my @args = qw( --proximate=20 --nogroup -i --sort -P court );

    ack_lists_match( [ @args, @files ], \@expected, '-P overrides --prox' );
};

done_testing();

exit 0;
