#!perl

use warnings;
use strict;

use Test::More tests => 1;

use lib 't';
use Util;

prep_environment();

subtest 'Double-hyphen allows hyphens after' => sub {
    plan tests => 1;

    my $cask = reslash( 't/text/amontillado.txt' );
    my $bill = reslash( 't/text/bill-of-rights.txt' );

    my @expected = line_split( <<"HERE" );
$cask:284:to the yells of him who clamored. I re-echoed--I aided--I surpassed
$cask:327:I re-erected the old rampart of bones. For the half of a century
$bill:53:fact tried by a jury, shall be otherwise re-examined in any Court of
HERE

    my @files = qw( t/text/ );
    my @args = qw( -i --sort -- -E ); # The -i must be in force for the /-E/ to find "-e"

    ack_lists_match( [ @args, @files ], \@expected, 'Looking for militia with metacharacters' );
};

done_testing();

exit 0;
