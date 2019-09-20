#!perl

use strict;
use warnings;

use Test::More tests => 4;
use lib 't';
use Util;
use File::Temp;

prep_environment();

WITHOUT_S: {
    my @files = qw( non-existent-file.txt );
    my @args  = qw( search-term );
    my (undef, $stderr) = run_ack_with_stderr( @args, @files );

    is( @{$stderr}, 1, 'Exactly one line of error' );
    like( $stderr->[0], qr/\Qnon-existent-file.txt: No such file or directory\E/, q{Error if there's no file} );
}

WITH_S: {
    my @files = qw( non-existent-file.txt );
    my @args  = qw( search-term -s );
    my (undef, $stderr) = run_ack_with_stderr( @args, @files );

    is_empty_array( $stderr, 'Nothing in stderr' );
}

# Test on restricted directories.
SKIP: {
    skip 'Fails under Travis.  See GH#200.', 1 if $ENV{TRAVIS};

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
