package RangeFile;

# For testing the range function.

use warnings;
use strict;
use 5.010;

# This function calls print on "foo".
sub foo {
    print 'foo';
    return 1;
}

my $print = 1;
my $update = 5;

sub bar {
    print 'bar';
    return 2;
}
my $task = 'print';
$update = 12;

1;
