#!perl

use warnings;
use strict;

use Test::More tests => 1;

use lib 't';
use Util;

prep_environment();


PIPE_INTO_DASH_C: {
    my $file = 't/text/raven.txt';
    my @args = qw( nevermore -i -c );
    my @results = pipe_into_ack( $file, @args );

    is_deeply( \@results, [ 11 ], 'Piping into ack --count should return one line of results' );
}


exit 0;
