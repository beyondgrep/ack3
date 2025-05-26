#!perl

use strict;
use warnings;

use Test::More tests => 1;
use lib 't';
use Util;
use File::Temp;

prep_environment();

RESTRICTED_DIRECTORIES: {
    my @args = qw( hello -s );

    my $dir = File::Temp->newdir;
    my $wd  = getcwd_clean();

    safe_chdir( $dir->dirname );

    safe_mkdir( 'foo' );
    write_file( 'foo/bar' => "hello\n" );
    write_file( 'baz'     => "hello\n" );

    chmod 0000, 'foo';
    chmod 0000, 'baz';

    my (undef, $stderr) = run_ack_with_stderr( @args );

    is_empty_array( $stderr, 'Nothing in stderr' );

    safe_chdir( $wd );
}

done_testing();
exit 0;
