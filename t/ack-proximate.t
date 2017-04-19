#!perl -T

use warnings;
use strict;

use Test::More tests => 2;

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



done_testing();

exit 0;
