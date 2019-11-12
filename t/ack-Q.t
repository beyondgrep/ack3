#!perl

use strict;
use warnings;

use Test::More;

plan tests => 2;

use lib 't';
use Util;

prep_environment();

# The unquoted "+" in "svn+ssh" will make the match fail.

subtest 'Plus sign' => sub {
    plan tests => 3;

    my @args = qw( svn+ssh t/swamp );
    ack_lists_match( [ @args ], [], 'No matches without the -Q' );

    my $target = reslash( 't/swamp/Rakefile' );
    my @expected = line_split( <<"HERE" );
$target:44:  baseurl = "svn+ssh:/#{ENV[\'USER\']}\@rubyforge.org/var/svn/#{PKG_NAME}"
$target:50:  baseurl = "svn+ssh:/#{ENV[\'USER\']}\@rubyforge.org/var/svn/#{PKG_NAME}"
HERE
    for my $arg ( qw( -Q --literal ) ) {
        ack_lists_match( [ @args, $arg ], \@expected, "$arg should make svn+ssh finable" );
    }
};


subtest 'Square brackets' => sub {
    plan tests => 4;

    my @args = qw( [ack] t/swamp );
    my @results = run_ack( @args );
    cmp_ok( scalar @results, '>', 100, 'Without quoting, the [ack] returns many matches' );

    my $target = reslash( 't/swamp/Makefile' );
    my @expected = line_split( <<"HERE" );
$target:15:#     EXE_FILES => [q[ack]]
$target:17:#     NAME => q[ack]
HERE
    for my $arg ( qw( -Q --literal ) ) {
        ack_lists_match( [ @args, $arg ], \@expected, "$arg should make svn+ssh finable" );
    }
};

exit 0;
