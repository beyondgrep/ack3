#!perl

use warnings;
use strict;

use Test::More tests => 7;

use lib 't';
use Util;

prep_environment();

my @full_speech = <DATA>;
chomp @full_speech;

my @johnny_rebeck = read_file( 't/range/johnny-rebeck.txt' );
chomp @johnny_rebeck;

subtest 'Gettysburg without --passthru' => sub {
    plan tests => 2;

    my @expected = line_split( <<'HERE' );
Now we are engaged in a great civil war, testing whether that nation,
on a great battle-field of that war. We have come to dedicate a portion
HERE

    @expected = color_match( qr/war/, @expected );

    my @files = qw( t/text/gettysburg.txt );
    my @args = qw( war --color );
    my @results = run_ack( @args, @files );

    lists_match( \@results, \@expected, 'Search for war' );
};


subtest 'Gettysburg with --passthru' => sub {
    plan tests => 2;

    my @expected = color_match( qr/war/, @full_speech );

    my @files = qw( t/text/gettysburg.txt );
    my @args = qw( war --passthru --color );
    my @results = run_ack( @args, @files );

    lists_match( \@results, \@expected, q{Still lookin' for war, in passthru mode} );
};


subtest '--passthru with/without ranges' => sub {
    plan tests => 4;

    my @args = qw( Rebeck --passthru --color t/range/johnny-rebeck.txt );
    my @expected = color_match( qr/Rebeck/, @johnny_rebeck );

    my @results = run_ack( @args );
    lists_match( \@results, \@expected, q{Searching without a range} );

    my @range_expected;
    my $nmatches = 0;
    for my $line ( @johnny_rebeck ) {
        if ( $line =~ /Rebeck/ ) {
            ++$nmatches;
            if ( $nmatches == 2 || $nmatches == 3 ) {
                ($line) = color_match( qr/Rebeck/, $line );
            }
        }
        push( @range_expected, $line );
    }
    @results = run_ack( @args, '--range-start=CHORUS', '--range-end=VERSE' );
    lists_match( \@results, \@range_expected, q{Searching with a range} );
};


# This tests the filename/lineno separators.
subtest 'With filename' => sub {
    plan tests => 2;

    my $ozy = reslash( 't/text/ozymandias.txt' );
    my @expected = line_split( <<"HERE" );
$ozy-1-I met a traveller from an antique land
$ozy-2-Who said: Two vast and trunkless legs of stone
$ozy-3-Stand in the desert... Near them, on the sand,
$ozy:4:Half sunk, a shattered visage lies, whose frown,
$ozy:5:And wrinkled lip, and sneer of cold command,
$ozy-6-Tell that its sculptor well those passions read
$ozy:7:Which yet survive, stamped on these lifeless things,
$ozy-8-The hand that mocked them, and the heart that fed:
$ozy-9-And on the pedestal these words appear:
$ozy-10-'My name is Ozymandias, king of kings:
$ozy-11-Look on my works, ye Mighty, and despair!'
$ozy-12-Nothing beside remains. Round the decay
$ozy-13-Of that colossal wreck, boundless and bare
$ozy-14-The lone and level sands stretch far away.
HERE

    my @results = run_ack( qw( li\w+  t/text/ozymandias.txt -H --passthru ) );

    lists_match( \@results, \@expected, q{With filename} );
};


subtest 'With filename and --not' => sub {
    plan tests => 2;

    my $ozy = reslash( 't/text/ozymandias.txt' );
    my @expected = line_split( <<"HERE" );
$ozy-1-I met a traveller from an antique land
$ozy-2-Who said: Two vast and trunkless legs of stone
$ozy-3-Stand in the desert... Near them, on the sand,
$ozy:4:Half sunk, a shattered visage lies, whose frown,
$ozy:5:And wrinkled lip, and sneer of cold command,
$ozy-6-Tell that its sculptor well those passions read
$ozy-7-Which yet survive, stamped on these lifeless things,
$ozy-8-The hand that mocked them, and the heart that fed:
$ozy-9-And on the pedestal these words appear:
$ozy-10-'My name is Ozymandias, king of kings:
$ozy-11-Look on my works, ye Mighty, and despair!'
$ozy-12-Nothing beside remains. Round the decay
$ozy-13-Of that colossal wreck, boundless and bare
$ozy-14-The lone and level sands stretch far away.
HERE

    # Same results as the "With filename" test except that we exclude "survive".
    my @results = run_ack( qw( li\w+  t/text/ozymandias.txt -H --passthru --not survive ) );

    lists_match( \@results, \@expected, q{With filename} );
};


SKIP: {
    skip 'Input options have not been implemented for Win32 yet', 2 if is_windows();

    # Some lines will match, most won't.
    my @ack_args = qw( war --passthru --color );
    my @results = pipe_into_ack( 't/text/gettysburg.txt', @ack_args );

    is( scalar @results, scalar @full_speech, 'Got all the lines back' );

    my @escaped_lines = grep { /\e/ } @results;
    is( scalar @escaped_lines, 2, 'Only two lines are highlighted' );
}

done_testing();
exit 0;


sub color_match {
    my $re    = shift;
    my @lines = @_;

    for my $line ( @lines ) {
        if ( $line =~ /$re/ ) {
            $line =~ s/($re)/\e[30;43m$1\e[0m/g;
            $line .= "\e[0m\e[K";
        }
    }

    return @lines;
}


__DATA__
Four score and seven years ago our fathers brought forth on this
continent, a new nation, conceived in Liberty, and dedicated to the
proposition that all men are created equal.

Now we are engaged in a great civil war, testing whether that nation,
or any nation so conceived and so dedicated, can long endure. We are met
on a great battle-field of that war. We have come to dedicate a portion
of that field, as a final resting place for those who here gave their
lives that that nation might live. It is altogether fitting and proper
that we should do this.

But, in a larger sense, we can not dedicate -- we can not consecrate --
we can not hallow -- this ground. The brave men, living and dead, who
struggled here, have consecrated it, far above our poor power to add or
detract. The world will little note, nor long remember what we say here,
but it can never forget what they did here. It is for us the living,
rather, to be dedicated here to the unfinished work which they who
fought here have thus far so nobly advanced. It is rather for us to be
here dedicated to the great task remaining before us -- that from these
honored dead we take increased devotion to that cause for which they gave
the last full measure of devotion -- that we here highly resolve that
these dead shall not have died in vain -- that this nation, under God,
shall have a new birth of freedom -- and that government of the people,
by the people, for the people, shall not perish from the earth.
