#!perl -T

use warnings;
use strict;

use Test::More tests => 5;

use lib 't';
use Util;

prep_environment();

subtest 'Grouped proximate' => sub {
    plan tests => 1;

    my $myth = reslash( 't/text/science-of-myth.txt' );
    my $sue  = reslash( 't/text/boy-named-sue.txt' );
    my @expected = line_split( <<"EOF" );
$sue
11:Some gal would giggle and I'd turn red
12:And some guy'd laugh and I'd bust his head,

$myth
10:Somehow no matter what the world keeps turning
11:Somehow we get by without ever learning

21:'cause some things are better left without a doubt

23:Somehow no matter what the world keeps turning
24:Somehow we get by without ever learning
EOF

    my @files = qw( t/text );
    my @args = qw( --proximate -i --group --sort some );

    ack_lists_match( [ @args, @files ], \@expected, 'Grouped proximate' );
};


subtest 'Ungrouped proximate' => sub {
    plan tests => 1;

    my $myth = reslash( 't/text/science-of-myth.txt' );
    my $sue  = reslash( 't/text/boy-named-sue.txt' );
    my @expected = line_split( <<"EOF" );
$sue:11:Some gal would giggle and I'd turn red
$sue:12:And some guy'd laugh and I'd bust his head,

$myth:10:Somehow no matter what the world keeps turning
$myth:11:Somehow we get by without ever learning

$myth:21:'cause some things are better left without a doubt

$myth:23:Somehow no matter what the world keeps turning
$myth:24:Somehow we get by without ever learning
EOF

    my @files = qw( t/text );
    my @args = qw( --proximate -i --nogroup --sort some );

    ack_lists_match( [ @args, @files ], \@expected, 'Ungrouped proximate' );
};


subtest 'Grouped proximate=2' => sub {
    plan tests => 1;

    my $sue = reslash( 't/text/boy-named-sue.txt' );
    my @expected = line_split( <<"EOF" );
$sue
4:Now, I don't blame him 'cause he run and hid

33:And I looked at him and my blood ran cold

36:Well, I hit him hard right between the eyes

46:I heard him laugh and then I heard him cuss,
48:He stood there lookin' at me and I saw him smile.

65:I called him my pa, and he called me his son,
67:And I think about him, now and then,
69:And if I ever have a son, I think I'm gonna name him
EOF

    my @files = qw( t/text );
    my @args = qw( --proximate=2 --group -w him );

    ack_lists_match( [ @args, @files ], \@expected, 'Grouped proximate=2' );
};



subtest 'Ungrouped proximate=2' => sub {
    plan tests => 1;

    my $sue = reslash( 't/text/boy-named-sue.txt' );
    my @expected = line_split( <<"EOF" );
$sue:4:Now, I don't blame him 'cause he run and hid

$sue:33:And I looked at him and my blood ran cold

$sue:36:Well, I hit him hard right between the eyes

$sue:46:I heard him laugh and then I heard him cuss,
$sue:48:He stood there lookin' at me and I saw him smile.

$sue:65:I called him my pa, and he called me his son,
$sue:67:And I think about him, now and then,
$sue:69:And if I ever have a son, I think I'm gonna name him
EOF

    my @files = qw( t/text );
    my @args = qw( --proximate=2 --nogroup -w him );

    ack_lists_match( [ @args, @files ], \@expected, 'Ungrouped proximate=2' );
};



# --proximate=3 is almost the same as --proximate=2.
subtest 'Ungrouped proximate=3' => sub {
    plan tests => 1;

    my $sue = reslash( 't/text/boy-named-sue.txt' );
    my @expected = line_split( <<"EOF" );
$sue:4:Now, I don't blame him 'cause he run and hid

$sue:33:And I looked at him and my blood ran cold
$sue:36:Well, I hit him hard right between the eyes

$sue:46:I heard him laugh and then I heard him cuss,
$sue:48:He stood there lookin' at me and I saw him smile.

$sue:65:I called him my pa, and he called me his son,
$sue:67:And I think about him, now and then,
$sue:69:And if I ever have a son, I think I'm gonna name him
EOF

    my @files = qw( t/text );
    my @args = qw( --proximate=3 --nogroup -w him );

    ack_lists_match( [ @args, @files ], \@expected, 'Ungrouped proximate=3' );
};



done_testing();

exit 0;
