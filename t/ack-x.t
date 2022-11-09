#!perl

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

subtest 'Basics' => sub {
    plan tests => 2;

    my @lhs_args = adjust_executable( build_ack_invocation( '--sort-files', '-g', '[vz]', 't/text' ) );
    my @rhs_args = adjust_executable( build_ack_invocation( '-x', '-i', 'that' ) );

    my ($stdout, $stderr);

    if ( is_windows() ) {
        ($stdout, $stderr) = run_cmd("@lhs_args | @rhs_args");
    }
    else {
        ($stdout, $stderr) = run_piped( \@lhs_args, \@rhs_args );
    }

    sets_match( $stdout, \@expected, __FILE__ );
    is_empty_array( $stderr );
};


# GH #175: -s doesn't work with -x
# We have to show that -s suppresses errors on missing and unreadable files,
# while still giving results on files that are there.
subtest 'GH #175' => sub {

    plan skip_all => q{Can't be run as root} if $> == 0;

    plan tests => 5;

    my @search_files;
    my @expected_errors;
    my $unreadable_file;    # Can't be localized or else it will be cleaned up.

    my $nonexistent_filename = '/tmp/non-existent-file' . $$ . '.txt';
    push( @search_files, $nonexistent_filename );
    push( @expected_errors, qr/\Q$nonexistent_filename: No such file/ );

    if ( !is_windows() ) {
        $unreadable_file = create_tempfile();
        my $unreadable_filename = $unreadable_file->filename;
        my (undef, $result) = make_unreadable( $unreadable_filename );
        die $result if $result;

        push( @search_files, $unreadable_filename );
        push( @expected_errors, qr/\Q$unreadable_filename: Permission denied/ );
    }

    my $ok_file = create_tempfile( 'My Pal Foot-Foot', 'Foo Fighters', 'I pity the fool', 'Not a match' );
    push( @search_files, $ok_file );

    my $input_file = create_tempfile( @search_files );

    # Without -s, we get an error about the missing file.
    my ($stdout,$stderr) = pipe_into_ack_with_stderr( $input_file->filename, '-x', '-i', 'foo' );
    is( scalar @{$stdout}, 3, 'Got three matches' );

    my $n = 0;
    for my $error ( @{$stderr} ) {
        ++$n;
        my $expected = shift @expected_errors;
        like( $error, $expected, "Error #$n matches" );
    }
    pass( 'One freebie pass for Windows' ) if is_windows();

    # With -s, there is no warning.
    ($stdout,$stderr) = pipe_into_ack_with_stderr( $input_file->filename, '-x', '-i', '-s', 'foo' );
    is( scalar @{$stdout}, 3, 'Still got three matches' );
    is_empty_array( $stderr, 'No errors' );
};

done_testing();
exit 0;
