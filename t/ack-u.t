#!perl -T

use warnings;
use strict;

use Test::More tests => 4;

use lib 't';
use Util;
use Barfly;

prep_environment();

Barfly->run_tests( 't/ack-u.barfly' );

my $bill_ = reslash( 't/text/bill-of-rights.txt' );
my $space = ' ' x length($bill_);

subtest 'Single file' => sub {
    plan tests => 1;

    my @expected = line_split( <<'EOF' );
A well regulated Militia, being necessary to the security of a free State,
                 ^^^^^^^
cases arising in the land or naval forces, or in the Militia, when in
                                                     ^^^^^^^
EOF

    my @files = $bill_;
    my @args  = ( qw( -u ), 'Militia' );

    ack_lists_match( [ @args, @files ], \@expected, 'Single file' );
};


subtest 'Grouped' => sub {
    plan tests => 1;

    my @expected = line_split( <<"EOF" );
$bill_
10:A well regulated Militia, being necessary to the security of a free State,
                    ^^^^^^^
31:cases arising in the land or naval forces, or in the Militia, when in
                                                        ^^^^^^^
EOF

    my @files = qw( t/text/bill-of-rights.txt t/text/ozymandias.txt ); # Don't want Constitution in here.
    my @args  = ( qw( -u --group ), 'Militia' );

    ack_lists_match( [ @args, @files ], \@expected, 'Grouped' );
};


subtest 'Not grouped, with leading filename' => sub {
    my @expected = line_split( <<"EOF" );
$bill_:10:A well regulated Militia, being necessary to the security of a free State,
$space                     ^^^^^^^
$bill_:31:cases arising in the land or naval forces, or in the Militia, when in
$space                                                         ^^^^^^^
EOF

    my $regex = 'Militia';
    my @files = $bill_;
    my @args  = ( qw( -u --nogroup -H ), $regex );

    ack_lists_match( [ @args, @files ], \@expected, "Looking for $regex - before with line numbers" );
};
done_testing();

exit 0;
