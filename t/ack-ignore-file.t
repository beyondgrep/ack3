#!perl -T

use strict;
use warnings;
use Test::More tests => 10;

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

# is:xxx matching

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
    [qw( -f t/swamp/groceries --ignore-file=is:fruit --ignore-file=is:junk )],
    [ @meat ],
    'Multiple is arguments'
);


# match:xxx matching
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
