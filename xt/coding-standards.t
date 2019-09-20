#!perl

use warnings;
use strict;

use lib 't';
use File::Next;
use Util;

use Test::More;


# Get all the ack component files.
my @files = ( 'ack' );
my $libs = File::Next::files( { descend_filter => sub { !/\Q.git/ }, file_filter => sub { /\.pm$/ } }, 'lib' );
while ( my $file = $libs->() ) {
    push @files, $file;
}
@files == 20 or die 'I should have exactly 20 modules + ack';

# Get all the test files.
for my $spec ( 't/*.t', 'xt/*.t' ) {
    my @these_files = glob( $spec ) or die "Couldn't find any $spec";
    push( @files, @these_files );
}

@files = grep { !/lowercase.t/ } @files; # lowercase.t has hi-bit and it's OK.

plan tests => scalar @files;

for my $file ( @files ) {
    subtest $file => sub {
        plan tests => 3;

        my @lines = read_file( $file );
        my $text = join( '', @lines );

        chomp @lines;
        my $ok = 1;
        my $lineno = 0;
        for my $line ( @lines ) {
            ++$lineno;
            if ( $line =~ /[^ -~]/ ) {
                my $col = $-[0] + 1;
                diag( "$file has hi-bit characters at $lineno:$col" );
                $ok = 0;
            }
            if ( $line =~ /\s+$/ ) {
                diag( "$file has trailing whitespace on line $lineno" );
                $ok = 0;
            }
        }
        ok( $ok, "$file: No hi-bit characters found and no trailing whitespace" );
        ok( $lines[-1] ne '', "$file: Doesn't end with an empty line" );

        is( index($text, "\t"), -1, "$file should have no embedded tabs" );
    }
}
