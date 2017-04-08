#!perl -T

use warnings;
use strict;
use Test::More tests => 23;

use App::Ack;   # For the VERSION
use File::Next;
use Test::Harness;
use Getopt::Long;
use Pod::Usage;
use File::Spec;

my @modules = qw(
    File::Next
    File::Spec
    Getopt::Long
    Pod::Usage
    Test::Harness
    Test::More
);

pass( 'All external modules loaded' );

diag( "Testing ack version $App::Ack::VERSION under Perl $], $^X" );
for my $module ( @modules ) {
    no strict 'refs';
    my $ver = ${$module . '::VERSION'};
    diag( "Using $module $ver" );
}

my $iter = File::Next::files( { file_filter => sub { /\.pm$/ } }, 'blib' );

while ( my $file = $iter->() ) {
    my $module = $file;
    $module =~ s{blib/lib/}{};
    $module =~ s{\.pm$}{};
    $module =~ s{/}{::}g;

    $module =~ /^([a-z::]+)$/i or die "Invalid module name $module";
    $module = $1;   # Untainted
    ok( eval "use $module; 1;", "use $module" );
}

done_testing();
