#!perl -T

# Checks that we are not using core C<die> or C<warn> except in very specific places.

use warnings;
use strict;

use Test::More tests => 2;

use lib 't';
use Util;

prep_environment();

my $ack_pm = quotemeta( reslash( 'blib/lib/App/Ack.pm' ) );

for my $word ( qw( warn die ) ) {
    subtest "Finding $word" => sub {
        plan tests => 4;

        my @args = ( '(?<!:)\b' . $word . '\b', '-I', 'blib/lib' );
        my @results = run_ack( @args );

        like( $results[0], qr/^$ack_pm:\d+:=head2 $word/, 'POD' );
        like( $results[1], qr/^$ack_pm:\d+:sub $word/, 'sub' );
        is( scalar @results, 2, 'Exactly two hits' );
    };
}

exit 0;
