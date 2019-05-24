#!perl -T

use strict;
use warnings;

use Test::More tests => 2;

use lib 't';
use Util;

prep_environment();

my $ozy__ = reslash( 't/text/ozymandias.txt' );
my $raven = reslash( 't/text/raven.txt' );

my @expected = line_split( <<"HERE" );
$ozy__:6:Tell that its sculptor well those passions read
$ozy__:8:The hand that mocked them, and the heart that fed:
$ozy__:13:Of that colossal wreck, boundless and bare
$raven:17:So that now, to still the beating of my heart, I stood repeating
$raven:26:That I scarce was sure I heard you" -- here I opened wide the door: --
$raven:29:Deep into that darkness peering, long I stood there wondering, fearing,
$raven:38:"Surely," said I, "surely that is something at my window lattice;
$raven:59:For we cannot help agreeing that no living human being
$raven:65:That one word, as if his soul in that one word he did outpour.
$raven:75:Till the dirges of his Hope that melancholy burden bore
$raven:88:On the cushion's velvet lining that the lamplight gloated o'er,
$raven:107:By that Heaven that bends above us, by that God we both adore,
$raven:113:"Be that word our sign of parting, bird or fiend!" I shrieked, upstarting:
$raven:115:Leave no black plume as a token of that lie thy soul hath spoken!
$raven:122:And his eyes have all the seeming of a demon's that is dreaming,
$raven:124:And my soul from out that shadow that lies floating on the floor
HERE

my $perl = caret_X();
my @lhs_args = ( $perl, '-Mblib', build_ack_invocation( '--sort-files', '-g', '[vz]', 't/text' ) );
my @rhs_args = ( $perl, '-Mblib', build_ack_invocation( '-x', '-i', 'that' ) );

if ( $ENV{'ACK_TEST_STANDALONE'} ) {
    @lhs_args = grep { $_ ne '-Mblib' } @lhs_args;
    @rhs_args = grep { $_ ne '-Mblib' } @rhs_args;
}

my ($stdout, $stderr);

if ( is_windows() ) {
    ($stdout, $stderr) = run_cmd("@lhs_args | @rhs_args");
}
else {
    ($stdout, $stderr) = run_piped( \@lhs_args, \@rhs_args );
}

sets_match( $stdout, \@expected, __FILE__ );
is_empty_array( $stderr );

done_testing();
exit 0;
