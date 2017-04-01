#!perl -T

use warnings;
use strict;

use Test::More tests => 4;

use lib 't';
use Util;
use Barfly;

prep_environment();

Barfly->run_tests( 't/ack-u.barfly' );

subtest 'Single file' => sub {
    plan tests => 2;

    my $target_file = reslash( 't/text/boy-named-sue.txt' );
    my @expected = line_split( <<"EOF" );
But the meanest thing that he ever did
                ^^^^^
Bill or George! Anything but Sue! I still hate that name!
                   ^^^^^
EOF

    my @files = $target_file;
    my @args  = ( qw( -u ), 'thing' );

    ack_lists_match( [ @args, @files ], \@expected, 'Single file' );
};


subtest 'Grouped' => sub {
    plan tests => 2;

    my $target_file = reslash( 't/text/boy-named-sue.txt' );
    my @expected = line_split( <<"EOF" );
$target_file
70:Bill or George! Anything but Sue! I still hate that name!
                   ^^^^^^^^
EOF

    my @files = 't/text/';
    my @args  = ( qw( -u --group ), 'Anything' );

    ack_lists_match( [ @args, @files ], \@expected, 'Grouped' );
};


subtest 'Not grouped, with leading filename' => sub {
    my $target_file = reslash( 't/text/boy-named-sue.txt' );
    my $spacing____ = ' ' x length($target_file);

    my @expected = line_split( <<"EOF" );
$target_file:5:But the meanest thing that he ever did
$spacing____                   ^^^^^
$target_file:70:Bill or George! Anything but Sue! I still hate that name!
$spacing____                       ^^^^^
EOF

    my $regex = 'thing';
    my @files = $target_file;
    my @args  = ( qw( -u --nogroup -H ), $regex );

    ack_lists_match( [ @args, @files ], \@expected, "Looking for $regex - before with line numbers" );
};
done_testing();

exit 0;
