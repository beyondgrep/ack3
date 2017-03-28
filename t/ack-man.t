#!perl -T

use strict;
use warnings;

use lib 't';
use Util;

use Test::More tests => 2;

prep_environment();

# Some things to expect, not all.
my @manual_sections = qw(
    AUTHOR
    BUGS
    SUPPORT
);

my @faq_sections = qw(
    FAQ
);

subtest 'ack --man' => sub {
    local $TODO = 'ack-standalone currently dumps all sections';
    plan tests => 5;

    my ($stdout, $stderr) = run_ack_with_stderr( '--man' );
    is_empty_array( $stderr, 'Nothing in STDERR' );
    want( $stdout, \@manual_sections );
    dont( $stdout, \@faq_sections );
};

subtest 'ack --faq' => sub {
    local $TODO = 'ack-standalone currently dumps all sections';
    plan tests => 5;

    my ($stdout, $stderr) = run_ack_with_stderr( '--faq' );
    is_empty_array( $stderr, 'Nothing in STDERR' );
    want( $stdout, \@faq_sections );
    dont( $stdout, \@manual_sections );
};

done_testing();

exit 0;


sub want {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $stdout   = shift;
    my $sections = shift;
    # We're sloppy with checking for headings because of potential embedded ANSI codes.
    for my $wanted ( @{$sections} ) {
        my $found = scalar grep { /\Q$wanted/ } @{$stdout};
        is( $found, 1, "Found one $wanted section" );
    }

    return;
}


sub dont {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $stdout   = shift;
    my $sections = shift;

    for my $verboten ( @{$sections} ) {
        my $found = scalar grep { /\Q$verboten/ } @{$stdout};
        is( $found, 0, "Find zero $verboten sections" );
    }

    return;
}
