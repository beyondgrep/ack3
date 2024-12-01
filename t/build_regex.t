#!perl

use warnings;
use strict;

use Test::More tests => 4;

use App::Ack;


PLAIN: {
    _check(
        'foo',
        {},
        '(?-xism:foo)',
        '(?m-xis:foo)',
        'Nuthin fancy'
    );
}


DASH_Q: {
    _check(
        'foo',
        { Q => 1 },
        '(?-xism:foo)',
        '(?m-xis:foo)',
        'Nothing for -Q to do'
    );
    _check(
        'thing^ and ($foo)',
        { Q => 1 },
        '(?-xism:thing\^\ and\ \(\$foo\))',
        undef,  # No scan regex when there are anchors
        '-Q has things to escape'
    );
}


DASH_i: {
    _check(
        'NeXT',
        { i => 1 },
        '(?-xism:(?i)NeXT)',
        '(?m-xis:(?i)NeXT)',
        'Simple -i'
    );
}


exit 0;


sub _check {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $str       = shift;
    my $opt       = shift;
    my $exp_match = shift;
    my $exp_scan  = shift;
    my $msg       = shift or die 'Must provide a message';

    return subtest $msg => sub () {
        $opt = { %{$opt} };

        $opt->{$_} //= [] for qw( and or not );

        my ($match, $scan) = App::Ack::build_regex( $str, $opt );

        is( $match, $exp_match, 'match matches' );
        is( $scan, $exp_scan, 'scan matches' );
    };
}
