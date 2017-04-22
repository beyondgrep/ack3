#!perl -T

use warnings;
use strict;

use Test::More tests => 4;

use lib 't';
use Util;

prep_environment();

# We need to do this tediously here rather than with Barfly because
# Barfly relies on --underline working correctly.

my $july_ = reslash( 't/text/4th-of-july.txt' );
my $happy = reslash( 't/text/shut-up-be-happy.txt' );

# Spacing that the filenames take up.
my $spc_j = ' ' x length( $july_ );
my $spc_h = ' ' x length( $happy );

subtest 'Grouped --underline' => sub {
    plan tests => 1;

    my $july_ = reslash( 't/text/4th-of-july.txt' );
    my $happy = reslash( 't/text/shut-up-be-happy.txt' );

    my @expected = line_split( <<"EOF" );
$july_
12:Looking at me, telling me you love me,
                                 ^^^^

$happy
5:Do not attempt to contact loved ones, insurance agents or attorneys.
                            ^^^^
EOF

    my @files = qw( t/text );
    my @args = qw( love --underline --sort-files --group );

    ack_lists_match( [ @args, @files ], \@expected, 'Looking for love, grouped' );
};


subtest 'Ungrouped --underline' => sub {
    plan tests => 1;

    my @expected = line_split( <<"EOF" );
$july_:12:Looking at me, telling me you love me,
$spc_j                                  ^^^^
$happy:5:Do not attempt to contact loved ones, insurance agents or attorneys.
$spc_h                             ^^^^
EOF

    my @files = qw( t/text );
    my @args = qw( love --underline --sort-files --nogroup );

    ack_lists_match( [ @args, @files ], \@expected, 'Looking for love, ungrouped' );
};


subtest 'Grouped --underline with context' => sub {
    plan tests => 1;

    my @expected = line_split( <<"EOF" );
$july_
10-Chorus:
11-You were pretty as can be, sitting in the front seat
12:Looking at me, telling me you love me,
                                 ^^^^
13-And you're happy to be with me on the 4th of July
14-We sang "Stranglehold" to the stereo

t/text/shut-up-be-happy.txt
3-All Constitutional rights have been suspended.
4-Stay in your homes.
5:Do not attempt to contact loved ones, insurance agents or attorneys.
                            ^^^^
6-Shut up.
7-Do not attempt to think or depression may occur.
EOF

    my @files = qw( t/text );
    my @args = qw( love --underline --sort-files --group -C );

    ack_lists_match( [ @args, @files ], \@expected, 'Looking for love, grouped with context' );
};


subtest 'Ungrouped --underline with --context' => sub {
    plan tests => 1;

    my @expected = line_split( <<"EOF" );
$july_-10-Chorus:
$july_-11-You were pretty as can be, sitting in the front seat
$july_:12:Looking at me, telling me you love me,
$spc_j                                  ^^^^
$july_-13-And you're happy to be with me on the 4th of July
$july_-14-We sang "Stranglehold" to the stereo
--
$happy-3-All Constitutional rights have been suspended.
$happy-4-Stay in your homes.
$happy:5:Do not attempt to contact loved ones, insurance agents or attorneys.
$spc_h                             ^^^^
$happy-6-Shut up.
$happy-7-Do not attempt to think or depression may occur.
EOF

    my @files = qw( t/text );
    my @args = qw( love --underline --sort-files --nogroup -C );

    ack_lists_match( [ @args, @files ], \@expected, 'Looking for love, ungrouped' );
};

exit 0;
