#!/usr/bin/perl

use warnings;
use strict;
use 5.010;

use Benchmark qw( timethese );

my $x = 'this is a line of text and it is about this long I guess';

my $n = 5_000_000;
timethese( $n,
    {
        none => sub { $x =~ /\w+date/ },
        w    => sub { $x =~ /\b\w+date\b/ },
        wi   => sub { $x =~ /\b\w+date\b/i },
        i    => sub { $x =~ /\w+date/i },
    }
);
