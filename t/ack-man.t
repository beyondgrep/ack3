#!perl

use strict;
use warnings;
use 5.010001;

use lib 't';
use Util;

use Test::More;

plan tests => 2;

prep_environment();

my ($stdout, $stderr) = run_ack_with_stderr( '--man' );

my @lines = @{$stdout};
my $nlines = scalar @lines;
my $ok = ($nlines > 900) && ($nlines < 2000);

diag $nlines;
if ( !ok( $ok, "Manual should be between 900-2000 lines long but is actually $nlines long" ) ) {
    my @first = grep { defined } @lines[0..19];
    diag( '--man start=', explain( \@first ) );


    my @last = grep { defined } @lines[-20..-1];
    diag( '--man end=', explain( \@last ) );
}

my $filtered_stderr = filter_out_perldoc_noise( $stderr );
is_empty_array( $filtered_stderr, 'Nothing in STDERR' );

done_testing();

exit 0;
