#!perl -T

use strict;
use warnings;

use File::Temp;
use List::Util qw( any sum );
use Test::More;
use lib 't';
use Util;

my %types = (
    perl   => [qw{.pl .pod .pl .t}],
    python => [qw{.py}],
    ruby   => [qw{.rb Rakefile}],
);

plan tests => 4;

prep_environment();

my $wd = getcwd_clean();

my $tempdir = File::Temp->newdir;

safe_chdir( $tempdir->dirname );
write_file( '.ackrc', "--frobnicate\n" );

subtest 'Check --env and weird options' => sub {
    plan tests => 10;

    my $output = run_ack( '--env', '--help' );
    like( $output, qr/Usage: ack/ );

    $output = run_ack( '--env', '--thpppt' );
    like( $output, qr/ack --thpppt/ );

    $output = run_ack( '--env', '--bar' );
    like( $output, qr/It's a grep/ );

    $output = run_ack( '--env', '--cathy' );
    like( $output, qr/CHOCOLATE/ );

    $output = run_ack( '--env', '--version' );
    like( $output, qr/ack 2[.]999_\d+/ );
};

subtest 'Check for all the types' => sub {
    plan tests =>
        2
        + (scalar keys %types)
        + (sum map { scalar @{$_} } values %types);

    ( my $output, my $stderr ) = run_ack_with_stderr( '--env', '--help-types' );

    ok( (any { /Usage: ack/ } @{$output}), 'Found at least one usage line' );
    ok( (any { /Unknown option: frobnicate/ } @{$stderr}), 'Found the illegal option in the ackrc' );

    while ( my ($type,$checks) = each %types ) {
        my ( $matching_line ) = grep { /--\[no\]$type/ } @{$output};

        ok( $matching_line, "Got at least one for --$type" );
        foreach my $check (@{$checks}) {
            like( $matching_line, qr/\Q$check\E/ );
        }
    }
};

{
    my ($output, $stderr) = run_ack_with_stderr( '--env', '--man' );
    # Don't worry if man complains about long lines,
    # or if the terminal doesn't handle Unicode:
    is( scalar(grep { !m{can't\ break\ line
                     |Wide\ character\ in\ print
                     |Unknown\ escape\ E<0x[[:xdigit:]]+>}x } @{$stderr}),
        0,
        'Should have no output to stderr: ack --env --man' )
        or diag( join( "\n", 'STDERR:', @{$stderr} ) );

    my $first_two_lines = join( "\n", @{$output}[0,1] );
    like( $first_two_lines, qr/^NAME\s+ack(?:-standalone)?\s/sm );
}

safe_chdir( $wd );

exit 0;
