#!perl

use warnings;
use strict;

use Test::More tests => 12;

use App::Ack;


PLAIN: {
    _check(
        'foo',
        {},
        '(?-xism:foo)',
        '(?m-xis:foo)',
        'Nuthin fancy'
    );
    _check(
        'foo-bar',
        {},
        '(?-xism:foo-bar)',
        '(?m-xis:foo-bar)',
        'Not just a plain word'
    );
}


SMARTCASE: {
    _check(
        'foo',
        { S => 1 },
        '(?-xism:(?i)foo)',
        '(?m-xis:(?i)foo)',
        'Smartcase on a lowercase word'
    );
    _check(
        'Foo',
        { S => 1 },
        '(?-xism:Foo)',
        '(?m-xis:Foo)',
        'Smartcase on a mixed-case word'
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


DASH_w: {
    _check(
        'wookie',
        { w => 1 },
        '(?-xism:\b(?:wookie)\b)',
        '(?m-xis:wookie)',
        'Simple -w'
    );
    _check(
        'wookie-boogie',
        { w => 1 },
        '(?-xism:(?:^|\b|\s)\K(?:wookie-boogie)(?=\s|\b|$))',
        '(?m-xis:wookie-boogie)',
        'Not just a single word'
    );
    _check(
        'blah.*',
        { w => 1 },
        '(?-xism:(?:^|\b|\s)\K(?:blah.*)(?=\s|\b|$))',
        '(?m-xis:blah.*)',
        '-w on something ending with metacharacters'
    );
    _check(
        '[abc]thing',
        { w => 1 },
        '(?-xism:(?:^|\b|\s)\K(?:[abc]thing)(?=\s|\b|$))',
        '(?m-xis:[abc]thing)',
        '-w on something beginning with a range'
    );
    _check(
        '[abc]thing.+?',
        { w => 1 },
        '(?-xism:(?:^|\b|\s)\K(?:[abc]thing.+?)(?=\s|\b|$))',
        '(?m-xis:[abc]thing.+?)',
        '-w on something beginning with a range and ending with metacharacters'
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
