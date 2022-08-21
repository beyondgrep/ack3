#!perl

use strict;
use warnings;

use Test::More tests => 2;

use lib 't';
use Util;

prep_environment();

my @all = qw(
    t/swamp/groceries/another_subdir/fruit
    t/swamp/groceries/another_subdir/junk
    t/swamp/groceries/another_subdir/meat
    t/swamp/groceries/dir.d/fruit
    t/swamp/groceries/dir.d/junk
    t/swamp/groceries/dir.d/meat
    t/swamp/groceries/fruit
    t/swamp/groceries/junk
    t/swamp/groceries/meat
    t/swamp/groceries/subdir/fruit
    t/swamp/groceries/subdir/junk
    t/swamp/groceries/subdir/meat
);
my @meat = grep { /meat/ } @all;
my @junk = grep { /junk/ } @all;


subtest 'is:xxx matching' => sub {
    plan tests => 5;

    ack_sets_match(
        [qw( -f t/swamp/groceries )],
        [ @all ],
        'Unfiltered'
    );

    ack_sets_match(
        [qw( -f t/swamp/groceries --ignore-file=is:fruit )],
        [ @meat, @junk ],
        'Ignoring fruit with is'
    );

    ack_sets_match(
        [qw( -f t/swamp/groceries --ignore-file=is:bongo )],
        [ @all ],
        'Ignoring with is that does not match'
    );

    ack_sets_match(
        [qw( -f t/swamp/groceries --ignore-file=is:subdir )],
        [ @all ],
        '--ignore-file only operatoes on filenames, not dirnames'
    );
    ack_sets_match(
        [qw( -f t/swamp/groceries --ignore-file=is:fruit --ignore-file=is:junk )],
        [ @meat ],
        'Multiple is arguments'
    );
};


subtest 'Invalid invocation' => sub {
    plan tests => 8;

    my @bad_args = (
        '--ignore-file=foo',
        '--ignore-file=foo:bar',
    );

    for my $bad_arg ( @bad_args ) {
        my ( $man_output, $man_stderr ) = run_ack_with_stderr( $bad_arg );

        is_empty_array( $man_output, "No output for $bad_arg" );
        is( scalar @{$man_stderr}, 2, "Exactly two errors for $bad_arg" );
        like( $man_stderr->[0], qr/ack(?:-standalone)?: Unknown filter type 'foo'.  Type must be one of: ext, firstlinematch, is, match./ );
        like( $man_stderr->[1], qr/ack(?:-standalone)?: Invalid option on command line/ );
    }
};


done_testing();
exit 0;
