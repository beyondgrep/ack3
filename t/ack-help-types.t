#!perl

use strict;
use warnings;

use List::Util qw(sum);
use Test::More;

use lib 't';
use Util;

prep_environment();

my @types = (
    perl   => [qw{.pl .pod .pl .t}],
    python => [qw{.py}],
    ruby   => [qw{.rb Rakefile}],
);

plan tests => 11;

my @output = run_ack( '--help-types' );

while ( my ($type,$checks) = splice( @types, 0, 2 ) ) {
    my ( $matching_line ) = grep { /^    $type / } @output;

    ok( $matching_line, "A match should be found for $type in the output for --help-types" );

    foreach my $check (@{$checks}) {
        like( $matching_line, qr/\Q$check\E/, "Line for --$type in output for --help-types contains $check" );
    }
}

done_testing();

exit 0;
