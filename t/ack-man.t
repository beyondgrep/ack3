#!perl -T

use strict;
use warnings;
use 5.010001;

use lib 't';
use Util;

use Test::More;

plan skip_all => 'Travis has PATH problems that prevent this from running' if $ENV{TRAVIS};
# See https://github.com/beyondgrep/ack3/issues/176

my $is_standalone = $ENV{ACK_TEST_STANDALONE} // die 'ACK_TEST_STANDALONE is not set';
plan tests => $is_standalone ? 2 : 4;

prep_environment();

# Some things to expect, not all.
my @man_sections = _section( qw(
    AUTHOR
    BUGS
    SUPPORT
) );

my @faq_sections = _section( qw(
    FAQ
) );

my @cookbook_sections = _section( qw(
    COOKBOOK
) );

if ( $is_standalone ) {
    subtest '--man, --faq and --cookbook all do the same thing' => sub {
        plan tests => 6;

        for my $option ( qw( --man --faq --cookbook ) ) {
            my ($stdout, $stderr) = run_ack_with_stderr( $option );
            is_empty_array( $stderr, 'Nothing in STDERR' );
            $stdout = _clean( $stdout );
            want( $stdout, [@man_sections, @faq_sections, @cookbook_sections] );
        }
    };
    subtest '--faq and --cookbook should not show up in --help' => sub {
        plan tests => 2;

        my ( $output, undef ) = run_ack_with_stderr( '--help' );
        want( $output, [ _option( '--man' ) ] );
        dont( $output, [qw( --faq --cookbook )] );
    };
}
else {
    subtest 'ack --man' => sub {
        plan tests => 3;

        my ($stdout, $stderr) = run_ack_with_stderr( '--man' );
        is_empty_array( $stderr, 'Nothing in STDERR' );
        $stdout = _clean( $stdout );
        want( $stdout, [@man_sections] );
        dont( $stdout, [@faq_sections, @cookbook_sections] );
    };
    subtest 'ack --faq' => sub {
        plan tests => 3;

        my ($stdout, $stderr) = run_ack_with_stderr( '--faq' );
        is_empty_array( $stderr, 'Nothing in STDERR' );
        $stdout = _clean( $stdout );
        want( $stdout, [@faq_sections] );
        dont( $stdout, [@man_sections, @cookbook_sections] );
    };
    subtest 'ack --cookbook' => sub {
        plan tests => 3;

        my ($stdout, $stderr) = run_ack_with_stderr( '--cookbook' );
        is_empty_array( $stderr, 'Nothing in STDERR' );
        $stdout = _clean( $stdout );
        want( $stdout, [@cookbook_sections] );
        dont( $stdout, [@man_sections, @faq_sections] );
    };
    subtest '--faq and --cookbook should be in --help' => sub {
        my ( $output, undef ) = run_ack_with_stderr( '--help' );
        want( $output, [ map { _option($_) } qw( --man --faq --cookbook ) ] );
    };
}


done_testing();

exit 0;


sub want {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $stdout   = shift;
    my $patterns = shift;

    my $str = join( ', ', @{$patterns} );

    return subtest "want( $str )" => sub {
        plan tests => scalar @{$patterns};

        for my $wanted ( @{$patterns} ) {
            my @found = grep { /$wanted/ } @{$stdout};
            is( scalar @found, 1, "Found one $wanted section" );
        }
    };
}


sub dont {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $stdout   = shift;
    my $patterns = shift;

    my $str = join( ', ', @{$patterns} );

    return subtest "dont( $str )" => sub {
        plan tests => scalar @{$patterns};

        for my $verboten ( @{$patterns} ) {
            my @found = grep { /$verboten/ } @{$stdout};
            is_empty_array( [grep { /$verboten/ } @{$stdout}], "Find zero $verboten patterns" );
        }
    };
}


sub _section {
    my $str = shift;

    return qr/^$str$/sm;
}


sub _option {
    my $str = shift;

    return qr/^\s+$str\b/;
}


sub _clean {
    my $output = shift;

    s/.\cH//g for @{$output};

    return $output;
}
