#!perl

use strict;
use warnings;

use Test::More;

plan tests => 3;

use lib 't';
use Util;

prep_environment();

# The unquoted "+" in "svn+ssh" will make the match fail.
my @args = qw( svn+ssh t/swamp );

NO_MATCHES: {
    ack_lists_match( [ @args ], [], 'No matches without the -Q' );
}


WITH_Q_OPTION: {
    my $target = reslash( 't/swamp/Rakefile' );

    my @expected = line_split( <<"HERE" );
$target:44:  baseurl = "svn+ssh:/#{ENV[\'USER\']}\@rubyforge.org/var/svn/#{PKG_NAME}"
$target:50:  baseurl = "svn+ssh:/#{ENV[\'USER\']}\@rubyforge.org/var/svn/#{PKG_NAME}"
HERE
    for my $arg ( qw( -Q --literal ) ) {
        ack_lists_match( [ @args, $arg ], \@expected, "$arg should make svn+ssh finable" );
    }
}

exit 0;
