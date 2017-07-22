#!perl -T

use strict;
use warnings;

use Test::More tests => 3;

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


subtest 'match:xxx matching' => sub {
    plan tests => 6;

    # The match is case-insensitive, unaffected by -i or -I.
    for my $u ( 'u', 'U' ) {
        for my $I ( '-i', '-I', undef ) {
            my @args = ( qw( -f t/swamp/groceries ), "--ignore-file=match:$u" );
            push( @args, $I ) if defined $I;
            ack_sets_match(
                [ @args ],
                [ @meat ],
                'Should only match files with do not have "u" in them: ' . join( ' ', map { $_ // 'undef' } @args )
            );
        }
    }
};


subtest 'Invalid invocation' => sub {
    plan tests => 4;

    my @bad_args = (
        '--ignore-file=foo',
        '--ignore-file=foo:bar',
    );

    for my $bad_arg ( @bad_args ) {
        my ( $man_output, $man_stderr ) = run_ack_with_stderr( $bad_arg );

        is_empty_array( $man_output, 'No output' );
        is_deeply( $man_stderr,
            [
                q{ack: Unknown filter type 'foo'.  Type must be one of: ext, firstlinematch, is, match.},
                q{ack: Invalid option on command line},
            ],
            "Two error messages match for $bad_arg",
        );
    }
};


done_testing();
exit 0;
