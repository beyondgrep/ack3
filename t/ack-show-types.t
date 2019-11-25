#!perl

use warnings;
use strict;

use Test::More tests => 10;

use lib 't';
use Util;

prep_environment();

RUBY_AND_RAKE: {
    do_ruby_test( qw( -f --show-types t/swamp/Rakefile ) );
    do_ruby_test( qw( -g \bRakef --show-types t/swamp ) );
}


REQUIRE_F_OR_G: {
    my ( $stdout, $stderr ) = run_ack_with_stderr('--show-types');
    is_empty_array($stdout, 'No output');
    is(scalar(@{$stderr}), 1, 'A single line should be present on standard error');
    like($stderr->[0], qr/--show-types can only be used with -f or -g./, 'Right error message' );
    is(get_rc(), 255, 'The ack command should not fail');
}


exit 0;


sub do_ruby_test {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my @args = @_;

    my @results = run_ack( @args );

    is( scalar @results, 1, "Only one file should be returned from 'ack @args'" );
    sets_match( get_types( $results[0] ), [qw( ruby rake )], "'ack @args' must return all the expected types" );

    return;
}


sub get_types {
    my $line = shift;
    $line =~ s/.* => //;

    my @types = split( /,/, $line );

    return \@types;
}
