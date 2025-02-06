#!perl

use warnings;
use strict;
use 5.010;

use Test::More;

use lib 't';
use Util;

plan tests => 100;

prep_environment();

NOT: {
    _movies_are(
        [qw( Murray )],
        [
            'Caddyshack',
            'Ghostbusters',
            'Groundhog Day',
            'Little Shop of Horrors',
            'Stripes',
        ]
    );

    _movies_are(
        [qw( Murray --not Ramis )],
        [
            'Caddyshack',
            'Groundhog Day',
            'Little Shop of Horrors',
        ]
    );

    _movies_are(
        [qw( Murray --not Ramis --not Martin )],
        [
            'Caddyshack',
            'Groundhog Day',
        ]
    );

    _movies_are(
        [qw( Murray --not Martin --not Ramis )],
        [
            'Caddyshack',
            'Groundhog Day',
        ]
    );

    _movies_are(
        [qw( Murray --not Martin --not Ramis --not Chase )],
        [
            'Groundhog Day',
        ]
    );

    _movies_are(
        [qw( Murray --not Martin --not Ramis --not Chase --not Elliott )],
        []
    );

    _movies_are(
        [qw( Ramis --not Murray )],
        []
    );

    # Do some --not that aren't there.
    _movies_are(
        [qw( Murray --not Cher )],
        [
            'Caddyshack',
            'Ghostbusters',
            'Groundhog Day',
            'Little Shop of Horrors',
            'Stripes',
        ]
    );

    _movies_are(
        [qw( Cher --not Murray )],
        []
    );
}


AND: {
    _movies_are(
        [qw( Aykroyd )],
        [
            '1941',
            'The Blues Brothers',
            'Dragnet',
            'Ghostbusters',
            'Neighbors',
        ]
    );

    _movies_are(
        [qw( Aykroyd --and Belushi )],
        [
            '1941',
            'The Blues Brothers',
            'Neighbors',
        ]
    );

    _movies_are(
        [qw( Belushi --and Aykroyd )],
        [
            '1941',
            'The Blues Brothers',
            'Neighbors',
        ]
    );

    # Permute through all combinations.
    my @who = qw( Aykroyd Belushi Candy );
    for my $permutation ( permutate( @who ) ) {
        my @args = _argjoin( '--and', $permutation );
        _movies_are(
            [ @args ],
            [
                'The Blues Brothers',
            ]
        );
    }
}


OR: {
    _movies_are(
        [qw( Fisher )],
        [
            'The Blues Brothers',
            'When Harry Met Sally',
        ]
    );

    _movies_are(
        [qw( Crystal )],
        [
            'This is Spinal Tap',
            'When Harry Met Sally',
        ]
    );

    _movies_are(
        [qw( Crystal --or Fisher )],
        [
            'The Blues Brothers',
            'This is Spinal Tap',
            'When Harry Met Sally',
        ]
    );

    _movies_are(
        [qw( Fisher --or Crystal )],
        [
            'The Blues Brothers',
            'This is Spinal Tap',
            'When Harry Met Sally',
        ]
    );

    _movies_are(    # Note this is an --and.
        [qw( Fisher --and Crystal )],
        [
            'When Harry Met Sally',
        ]
    );

    # One of the OR options doesn't exist.
    _movies_are(
        [qw( Crystal --or Hemsworth )],
        [
            'This is Spinal Tap',
            'When Harry Met Sally',
        ]
    );
    _movies_are(
        [qw( Hemsworth --or Crystal )],
        [
            'This is Spinal Tap',
            'When Harry Met Sally',
        ]
    );

    _movies_are(
        [qw( Crystal --or Fisher --or Hemsworth )],
        [
            'The Blues Brothers',
            'This is Spinal Tap',
            'When Harry Met Sally',
        ]
    );

    # Permute through all combinations.
    my @who = qw( Crystal Fisher Hemsworth Moranis );
    for my $permutation ( permutate( @who ) ) {
        my @args = _argjoin( '--or', $permutation );
        _movies_are(
            [ @args ],
            [
                'The Blues Brothers',
                'Ghostbusters',
                'Little Shop of Horrors',
                'My Blue Heaven',
                'Spaceballs',
                'This is Spinal Tap',
                'When Harry Met Sally',
            ]
        );
    }
}



# XXX  We need tests on highlighting, too.
#
# XXX And tests on none of them matching.
# XXX And tests that --and themselves out of matching.
done_testing();
exit 0;


sub _movies_are {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $args = shift;
    my $exp  = shift;

    my @base_args = qw( -w -i --noenv );
    my @files = reslash( 't/text/movies.txt' );
    my @got = run_ack( @base_args, @{$args}, @files );

    s/:.+// for @got;

    return is_deeply( \@got, $exp, join( ' ', @{$args} ) );
}


sub _argjoin {
    my $opt  = shift;
    my $args = shift;

    my @args = map { ($_, $opt) } @{$args};

    pop @args;

    return @args;
}
