#!perl

use 5.010;
use strict;
use warnings;

use Test::More tests => 1;

use File::Spec ();
use File::Temp ();

use lib 't';
use Util;

prep_environment();

# Global:
# /tmp/x/etc/.ackrc
# /tmp/x/swamp

my $wd = getcwd_clean();

_test_naughty_ansi_filenames();

exit 0;

# Test project directory
# ackrc in /tmp/x/project/subdir/{naughtyAnsiFiles}
#
sub _test_naughty_ansi_filenames {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    return subtest subtest_name() => sub {
        plan tests => 6;

        my $base_obj = File::Temp->newdir;
        my $base = $base_obj->dirname;

        # /tmp/x/project
        my $projectdir = File::Spec->catdir( $base, 'project' );
        safe_mkdir( $projectdir );

        # /tmp/x/project/subdir/
        my $projectsubdir = File::Spec->catdir( $projectdir, 'subdir' );
        safe_mkdir( $projectsubdir );

        # These files have evil names, in the sense of ANSI terminal manipulation
        # so are generated and removed rather than shipped in t/

        # /tmp/x/project/subdir/${forged}
        # (1) Newline injection: filename splits ack output into two lines
        # original bash equivalent:
        # # FORGED=$(printf 'real\nFORGED:999:injected_content.pl')
        # # printf 'foo\n' > "./$FORGED"
        #
        my $forged = "real\nFORGED:999:injected_content.pl";
        my $projectfile = File::Spec->catfile( $projectsubdir, $forged );
        write_file( $projectfile, "foo FORGED\n" );

        # /tmp/x/project/subdir/${ansi}
        #  ANSI injection: ESC bytes change terminal appearance
        # # ANSI=$(printf 'file\033[31mRED\033[0m.pl')
        # # printf 'foo\n' > "./$ANSI"
        my $ansi = "file\033[31mRED\033[0m.pl";
        $projectfile = File::Spec->catfile( $projectsubdir, $ansi );
        write_file( $projectfile, "foo RED\n" );

        # /tmp/x/project/subdir/normal.pl
        # # printf 'foo\n' > .//normal.pl
        $projectfile = File::Spec->catfile( $projectsubdir, 'normal.pl' );
        write_file( $projectfile, "foo normal\n" );

        safe_chdir( $projectdir );

        # TO VIEW temp dir contents
        # system('ls', '-alr', 'subdir',);

        my %expect = (
            RED    => qr{\Qsubdir/file?[31mRED?[0m.pl\E},
            normal => qr{\Qsubdir/normal.pl\E},
            FORGED => qr{\Qsubdir/real?FORGED:999:injected_content.pl\E},
        );
        for my $name (qw[ RED normal FORGED ]){
            subtest "5_01_filter_listing_$name" => sub {
                plan tests => 3;
                # /tmp/x/project/.ackrc
                # _create_ackrc( $projectdir, "--$option=$option" ) ???

                # Explicitly pass --env or else the test will ignore .ackrc.
                my ( $stdout, $stderr ) = run_ack_with_stderr( '-g', '--env', $name  );

                # NOT is_empty_array( $stdout, 'No output with the errors' );
                is (scalar(@$stdout),1, "number of lines correct");
                like( $stdout->[0], $expect{$name},  "$name listing" );

                is_empty_array( $stderr, 'No errors with output' );
                # first_line_like( $stderr, qr/\Qsome error message/, "some error message" );
            };
        } # end for 1

        my %File = (
                 RED => qq{subdir/file\033\[31mRED\033\[0m.pl},
                 normal => qq{subdir/normal.pl},
                 FORGED => qq{subdir/real\nFORGED:injected_content.pl},
        );
        %expect = (
                 RED => qr{subdir/file[?][[]31mRED[?][[]0m[.]pl:1:foo},
                 normal => qr{subdir/normal.pl:1:foo},
                 FORGED => qr{subdir/real[?]FORGED:999:injected_content[.]pl:1:foo},
        );
        for my $name (qw[ RED normal FORGED ]){
            subtest "5_02_filter_match_$name" => sub {
                plan tests => 3;

                # /tmp/x/project/.ackrc
                # _create_ackrc( $projectdir, "--$option=$option" ) ???

                # Explicitly pass --env or else the test will ignore .ackrc.
                my ( $stdout, $stderr ) = run_ack_with_stderr( '--env', '--with-filename', "foo $name" , );

                # NOT is_empty_array( $stdout, 'No output with the errors' );
                is (scalar(@$stdout),1, "number of lines correct");
                first_line_like( $stdout, $expect{$name}, "on match, masked $name" );

                is_empty_array( $stderr, 'No errors with output' );
                # first_line_like( $stderr, qr/\Qsome error message/, "some error message" );

            };
        } # end for 2

        # Go back to working directory so the temporary directories can get erased.
        safe_chdir( $wd );
    };
}


