#!perl

# XXX This test need to include not-forbidden-options, like --sort and --smart-case.

use strict;
use warnings;

use Test::More tests => 2;

use File::Spec ();
use File::Temp ();

use lib 't';
use Util;

prep_environment();

# Global:
# /tmp/x/etc/.ackrc
# /tmp/x/swamp

my $wd = getcwd_clean();

_test_project_ackrc();
_test_home_ackrc();

exit 0;

# Test project directory
# ackrc in /tmp/x/project/.ackrc
sub _test_project_ackrc {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    return subtest subtest_name() => sub {
        plan tests => 3;

        my $base_obj = File::Temp->newdir;
        my $base = $base_obj->dirname;

        # /tmp/x/project
        my $projectdir = File::Spec->catdir( $base, 'project' );
        safe_mkdir( $projectdir );

        # /tmp/x/project/subdir
        my $projectsubdir = File::Spec->catdir( $projectdir, 'subdir' );
        safe_mkdir( $projectsubdir );

        # /tmp/x/project/subdir/foo.pl
        my $projectfile = File::Spec->catfile( $projectsubdir, 'foo.pl' );
        write_file( $projectfile, '#!/usr/bin/perl' );

        safe_chdir( $projectdir );

        # All three of these options are illegal in a project .ackrc.
        for my $option ( qw( match output pager ) ) {
            subtest $option => sub {
                plan tests => 2;

                # /tmp/x/project/.ackrc
                _create_ackrc( $projectdir, "--$option=$option" );

                # Explicitly pass --env or else the test will ignore .ackrc.
                my ( $stdout, $stderr ) = run_ack_with_stderr( '-f', '--env' );

                is_empty_array( $stdout, 'No output with the errors' );
                if ( $option eq 'pager' ) {
                    first_line_like( $stderr, qr/\QOption --$option is forbidden in project .ackrc files/, "$option illegal" );
                }
                else {
                    first_line_like( $stderr, qr/\QOption --$option is forbidden in .ackrc files/, "$option illegal" );
                }
            };
        }

        # Go back to working directory so the temporary directories can get erased.
        safe_chdir( $wd );
    };
}


# Test home directory
# ackrc in  /tmp/x/home/.ackrc
# search in /tmp/x/swamp
sub _test_home_ackrc {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    return subtest subtest_name() => sub {
        plan tests => 3;

        my $base_obj = File::Temp->newdir;
        my $base = $base_obj->dirname;

        # /tmp/x/home
        my $homedir = File::Spec->catdir( $base, 'home' );
        safe_mkdir( $homedir );

        # /tmp/x/project
        my $projectdir = File::Spec->catdir( $base, 'project' );
        safe_mkdir( $projectdir );

        # /tmp/x/project/foo.pl
        my $projectfile = File::Spec->catfile( $projectdir, 'foo.pl' );
        write_file( $projectfile, '#!/usr/bin/perl' );

        safe_chdir( $projectdir );

        # --match and --output are illegal in a home .ackrc, but --pager is ok.
        for my $option ( qw( match output pager ) ) {
            subtest $option => sub {
                plan tests => 2;

                # /tmp/x/home/.ackrc
                _create_ackrc( $homedir, "--$option=$option" );
                local $ENV{HOME} = $homedir;

                # Explicitly pass --env or else the test will ignore .ackrc.
                my ( $stdout, $stderr ) = run_ack_with_stderr( '-f', '--env' );

                if ( $option eq 'pager' ) {
                    is_deeply( $stdout, [ 'foo.pl' ], 'Found foo.pl OK' );
                    is_empty_array( $stderr, '--pager is OK' );
                }
                else {
                    is_empty_array( $stdout, 'No output with the errors' );
                    first_line_like( $stderr, qr/\QOption --$option is forbidden in .ackrc files/, "$option illegal" );
                }
            };
        }

        # Go back to working directory so the temporary directories can get erased.
        safe_chdir( $wd );
    };
}


sub _create_ackrc {
    my $dir    = shift;
    my $option = shift;

    my $ackrc = File::Spec->catfile( $dir, '.ackrc' );
    write_file( $ackrc, join( "\n", '--sort-files', $option, '--smart-case', '' ) );

    return $ackrc;
}
