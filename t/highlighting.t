#!perl

use warnings;
use strict;

use Test::More tests => 24;

use lib 't';
use Util;

prep_environment();


my @HIGHLIGHT = qw( --color --group --sort-files );

BASIC: {
    my @args  = qw( --sort-files Montresor t/text/ );

    my $expected_original = <<'END';
<t/text/amontillado.txt>
{99}:the catacombs of the (Montresor)s.
{152}:"The (Montresor)s," I replied, "were a great and numerous family."
{309}:"For the love of God, (Montresor)!"
END

    _check_it( $expected_original, @args, @HIGHLIGHT );
}


METACHARACTERS: {
    my @args  = qw( --sort-files \w*rave\w* t/text/ );
    my $expected_original = <<'END';
<t/text/gettysburg.txt>
{13}:we can not hallow -- this ground. The (brave) men, living and dead, who

<t/text/ozymandias.txt>
{1}:I met a (traveller) from an antique land

<t/text/raven.txt>
{51}:By the (grave) and stern decorum of the countenance it wore,
{52}:"Though thy crest be shorn and shaven, thou," I said, "art sure no (craven),
END

    _check_it( $expected_original, @args, @HIGHLIGHT );
}


CONTEXT: {
    my @args  = qw( --sort-files free -C1 t/text/ );

    my $expected_original = <<'END';
<t/text/bill-of-rights.txt>
{3}-Congress shall make no law respecting an establishment of religion,
{4}:or prohibiting the (free) exercise thereof; or abridging the (free)dom of
{5}-speech, or of the press; or the right of the people peaceably to assemble,
--
{9}-
{10}:A well regulated Militia, being necessary to the security of a (free) State,
{11}-the right of the people to keep and bear Arms, shall not be infringed.

<t/text/constitution.txt>
{31}-respective Numbers, which shall be determined by adding to the whole
{32}:Number of (free) Persons, including those bound to Service for a Term
{33}-of Years, and excluding Indians not taxed, three fifths of all other

<t/text/gettysburg.txt>
{22}-these dead shall not have died in vain -- that this nation, under God,
{23}:shall have a new birth of (free)dom -- and that government of the people,
{24}-by the people, for the people, shall not perish from the earth.
END

    _check_it( $expected_original, @args, @HIGHLIGHT );
}


NOT: {
    ORIGINAL: {
        my @args = ( qw( judge -i ), 't/text/constitution.txt' );

        my $expected_original = <<'END';
Each House shall be the (Judge) of the Elections, Returns and Qualifications
(Judge)s of the supreme Court, and all other Officers of the United States,
shall (judge) necessary and expedient; he may, on extraordinary Occasions,
time ordain and establish. The (Judge)s, both of the supreme and inferior
the Land; and the (Judge)s in every State shall be bound thereby, any Thing
END

        _check_it( $expected_original, @args );
    }

    NOT: {
        my @args = ( qw( judge --not judges -i ), 't/text/constitution.txt' );

        my $expected_original = <<'END';
Each House shall be the (Judge) of the Elections, Returns and Qualifications
shall (judge) necessary and expedient; he may, on extraordinary Occasions,
END

        _check_it( $expected_original, @args );
    }

    NOT_AGAIN: {
        my @args = ( qw( judge --not all -i ), 't/text/constitution.txt' );

        my $expected_original = <<'END';
time ordain and establish. The (Judge)s, both of the supreme and inferior
END

        _check_it( $expected_original, @args );
    }
}


AND: {
    ORIGINAL: {
        my @args = ( qw( judge -i ), 't/text/constitution.txt' );

        my $expected_original = <<'END';
Each House shall be the (Judge) of the Elections, Returns and Qualifications
(Judge)s of the supreme Court, and all other Officers of the United States,
shall (judge) necessary and expedient; he may, on extraordinary Occasions,
time ordain and establish. The (Judge)s, both of the supreme and inferior
the Land; and the (Judge)s in every State shall be bound thereby, any Thing
END

        _check_it( $expected_original, @args );
    }

    AND: {
        my @args = ( qw( judge --and all -i ), 't/text/constitution.txt' );

        my $expected_original = <<'END';
Each House sh(all) be the (Judge) of the Elections, Returns and Qualifications
(Judge)s of the supreme Court, and (all) other Officers of the United States,
sh(all) (judge) necessary and expedient; he may, on extraordinary Occasions,
the Land; and the (Judge)s in every State sh(all) be bound thereby, any Thing
END

        _check_it( $expected_original, @args );
    }

    AND_AND: {
        my @args = ( qw( judge --and all --and \bthe\b -i ), 't/text/constitution.txt' );

        my $expected_original = <<'END';
Each House sh(all) be (the) (Judge) of (the) Elections, Returns and Qualifications
(Judge)s of (the) supreme Court, and (all) other Officers of (the) United States,
(the) Land; and (the) (Judge)s in every State sh(all) be bound thereby, any Thing
END

        _check_it( $expected_original, @args );
    }

}


OR: {
    ORIGINAL: {
        my @args = ( qw( judges -i ), 't/text/constitution.txt' );

        my $expected_original = <<'END';
(Judges) of the supreme Court, and all other Officers of the United States,
time ordain and establish. The (Judges), both of the supreme and inferior
the Land; and the (Judges) in every State shall be bound thereby, any Thing
END

        _check_it( $expected_original, @args );
    }

    OR: {
        my @args = ( qw( judges --or judge -i ), 't/text/constitution.txt' );

        my $expected_original = <<'END';
Each House shall be the (Judge) of the Elections, Returns and Qualifications
(Judges) of the supreme Court, and all other Officers of the United States,
shall (judge) necessary and expedient; he may, on extraordinary Occasions,
time ordain and establish. The (Judges), both of the supreme and inferior
the Land; and the (Judges) in every State shall be bound thereby, any Thing
END

        _check_it( $expected_original, @args );
    }

    OR_OR: {
        my @args = ( qw( judges --or judge --or amendment -i ), 't/text/constitution.txt' );

        my $expected_original = <<'END';
Each House shall be the (Judge) of the Elections, Returns and Qualifications
Representatives; but the Senate may propose or concur with (Amendment)s
(Judges) of the supreme Court, and all other Officers of the United States,
shall (judge) necessary and expedient; he may, on extraordinary Occasions,
time ordain and establish. The (Judges), both of the supreme and inferior
shall propose (Amendment)s to this Constitution, or, on the Application
Convention for proposing (Amendment)s, which, in either Case, shall be
Ratification may be proposed by the Congress; Provided that no (Amendment)
the Land; and the (Judges) in every State shall be bound thereby, any Thing
END

        _check_it( $expected_original, @args );
    }
}


exit 0;


sub _check_it {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $expected = shift;
    my @args = @_;

    $expected = windows_slashify( $expected ) if is_windows;

    my @expected = colorize( $expected );

    my @results = run_ack( @args, @HIGHLIGHT );

    return is_deeply( \@results, \@expected, 'Context is all good' );
}
