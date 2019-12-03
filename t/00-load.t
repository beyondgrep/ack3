#!perl

use 5.010;
use warnings;
use strict;

use Test::More tests => 20;

# Load all these modules to get their versions.
use App::Ack;
use File::Next;
use File::Spec;
use Getopt::Long;
use Pod::Perldoc;
use Pod::Text;
use Pod::Usage;
use Term::ANSIColor;
use Test::Harness;

my @modules = qw(
    File::Next
    File::Spec
    Getopt::Long
    Pod::Perldoc
    Pod::Text
    Pod::Usage
    Term::ANSIColor
    Test::Harness
    Test::More
);

pass( 'All external modules loaded' );

diag sprintf( 'Testing ack %s under Perl v%vd, %s', $App::Ack::VERSION, $^V, $^X );
for my $module ( @modules ) {
    no strict 'refs';
    my $ver = ${$module . '::VERSION'};
    diag( "Using $module $ver" );
}
diag( 'PATH=' . ($ENV{PATH} // '<undef>') );

# Find all the .pm files in blib/ and make sure they can be C<use>d.
my $iter = File::Next::files( { file_filter => sub { /\.pm$/ } }, 'blib' );
while ( my $file = $iter->() ) {
    $file =~ s/\.pm$// or die "There should be a .pm at the end of $file but there isn't";
    my @dirs = File::Spec->splitdir( $file );

    # Break apart the path, throw away blib/lib/, and reconstitute the module name.
    my $junk = shift @dirs;
    die unless $junk eq 'blib';

    $junk = shift @dirs;
    die unless $junk eq 'lib';

    my $module = join( '::', @dirs );
    $module =~ /^([a-z::]+)$/i or die "Invalid module name $module";
    $module = $1;   # Untainted
    my $rc = eval "use $module; 1;";
    ok( $rc, "use $module" );
}

done_testing();
