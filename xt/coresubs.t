#!perl

# Checks that we are not using core C<die> or C<warn> except in very specific places.
# Same with C<mkdir> and C<chdir>.
# Ignore the App::Ack::Docs modules since they're nothing but text.

## no critic ( Bangs::ProhibitDebuggingModules )

use warnings;
use strict;

use Test::More tests => 4;

use lib 't';
use Util;

prep_environment();

my $ack_pm = quotemeta( reslash( 'blib/lib/App/Ack.pm' ) );

my @exclusions = qw(
    --ignore-dir=dev
    --ignore-file=is:ack-standalone
);

for my $word ( qw( warn die ) ) {
    subtest "Finding $word" => sub {
        plan tests => 4;

        my @args = ( '(?<!:)\b' . $word . '\b', '-I', 'blib/lib', @exclusions, '--ignore-dir', 'garage' );
        my @results = run_ack( @args );

        like( $results[0], qr/^$ack_pm:\d+:=head2 $word/, 'POD' );
        like( $results[1], qr/^$ack_pm:\d+:sub $word/, 'sub' );
        is( scalar @results, 2, 'Exactly two hits' );
    };
}

# Don't use C<chdir> or C<mkdir>.  Use C<safe_chdir> and C<safe_mkdir>.
my $util_pm = quotemeta( reslash( 't/Util.pm' ) );
for my $word ( qw( chdir mkdir ) ) {
    subtest "Finding $word" => sub {
        plan tests => 3;

        my @args = ( '-w', '--ignore-file=is:coresubs.t', '--ignore-file=is:Dockerfile', '--ignore-dir=garage', @exclusions, $word );
        my @results = run_ack( @args );

        is( scalar @results, 1, 'Exactly one hit...' ) or do { require Data::Dumper; warn Data::Dumper::Dumper( \@results ) };
        like( $results[0], qr/^$util_pm.+CORE::$word/, '... and it is in the function in Util.pm that wraps the core call' );
    };
}

exit 0;
