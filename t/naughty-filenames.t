#!perl

use 5.010;
use strict;
use warnings;


use Test2::V0;
use Test2::Tools::Explain;

use File::Spec ();
use File::Temp ();

use utf8;
use open qw( :std :encoding(UTF-8) );
# May want to suggest (soft-test-pre-req) Unicode::GCString to make test tables pretty

use lib 't';
use Util;


prep_environment();

if ( is_windows() ) {
    plan skip_all => 'Test fails on Windows.';
    exit;
}
else {
    plan tests => 1;
}

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
        plan tests => 7;

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
        write_file( $projectfile, "foo\n" );

        # /tmp/x/project/subdir/${ansi}
        #  ANSI injection: ESC bytes change terminal appearance
        # # ANSI=$(printf 'file\033[31mRED\033[0m.pl')
        # # printf 'foo\n' > "./$ANSI"
        my $ansi = "file\033[31mRED\033[0m.pl";
        $projectfile = File::Spec->catfile( $projectsubdir, $ansi );
        write_file( $projectfile, "foo\n" );

        # /tmp/x/project/subdir/normal.pl
        # # printf 'foo\n' > .//normal.pl
        $projectfile = File::Spec->catfile( $projectsubdir, 'normal.pl' );
        write_file( $projectfile, "foo\n" );

        # Emoji in filename ... not tested, recognition hard
        # Emoji in filename : Wheelchair
        $projectfile = File::Spec->catfile( $projectsubdir, '♿.txt' );
        write_file( $projectfile, join(qq(\n),
                  "Unicode file name and contents; foo.",
                  "Wheel-chair (English) ♿",
            ));

        # Hungarian Phrase Book (from Monty Python)
        $projectfile = File::Spec->catfile( $projectsubdir, 'Magyar_társalgási_zsebkönyv.txt' );
        write_file( $projectfile, join( qq(\n),
                    "Unicode file name and contents (foo)",
                    "Magyar társalgási zsebkönyv   —   Hungarian Phrase Book",
                    "Angol társalgási zsebkönyv   —   English Phrase Book",
                    "A légpárnásom tele van angolnákkal.   —   My Hovercraft is full of eels",
                ));

        my $wd  = getcwd_clean();
        safe_chdir( $projectdir );

        # TO VIEW temp dir contents
        # system('ls', '-alr', 'subdir',);

        my %expect = (
            RED    => qr{\Qsubdir/file?[31mRED?[0m.pl\E},
            normal => qr{\Qsubdir/normal.pl\E},
            FORGED => qr{\Qsubdir/real?FORGED:999:injected_content.pl\E},
            Unicode=> qr{\Qsubdir/Magyar_társalgási_zsebkönyv.txt\E},
            Emoji  => qr{\Qsubdir/♿.txt\E},
        );
        subtest "5_01_filter_listing" => sub {
            plan tests => 5;
            # /tmp/x/project/.ackrc
            # _create_ackrc( $projectdir, "--$option=$option" ) ???

            # Explicitly pass --env or else the test will ignore .ackrc.
            my ( $stdout, $stderr ) = run_ack_with_stderr( '-f', '--env' );

                is (scalar(@$stdout),5, "number of lines correct");
                my $check;
                # Using Test2 is(), not Test::More is(), to use Bag to be insensitive
                # to order files are found on filesystem but keep them all in one test
                # (matching the advisory) rather than make 1 test per example file

                is ($stdout,
                    ($check=bag {
                        item match qr{\Qsubdir/file?[31mRED?[0m.pl\E};
                        item match qr{\Qsubdir/normal.pl\E};
                        item match qr{\Qsubdir/real?FORGED:999:injected_content.pl\E};
                        item match $expect{Unicode};
                        item match $expect{Emoji};
                        end(); # only these elements; use etc(); if don't-care if more.
                       }),
                   'Listing -f , w/ 2 filtered: ?...RED?, normal, ?FORGED.'
                   ) || diag explain {stdout => $stdout,
                                   # check=>$check,
                                 };

                is_empty_array( $stderr, 'No errors with output' );

           #
           ( $stdout, $stderr ) = run_ack_with_stderr( '-g', '--env' , 'ED'  );


                is ($stdout,
                    ($check=bag {
                        item match qr{\Qsubdir/file?[31mRED?[0m.pl\E};
                        item match qr{\Qsubdir/real?FORGED:999:injected_content.pl\E};
                        end; # only these elements; use etc(); if don't-care if more.
                       }),
                   'Listing -g  w/ 2 filtered: ?...RED?, ?FORGED.'
                   ) || diag explain {stdout => $stdout,
                                   # check=>$check,
                                 };

                is_empty_array( $stderr, 'No errors with output' );

            };
        subtest "5_02_filter_show-types" => sub {

            plan tests => 4;
            # /tmp/x/project/.ackrc
            # _create_ackrc( $projectdir, "--$option=$option" ) ???

            # Explicitly pass --env or else the test will ignore .ackrc.
            my ( $stdout, $stderr ) = run_ack_with_stderr( '-f', '--env', '--show-types', );

                my $check;
                # Using Test2 is(), not Test::More is(), to use Bag to be insensitive
                # to order files are found on filesystem but keep them all in one test
                # (matching the advisory) rather than make 1 test per example file

                is ($stdout,
                    ($check=bag {
                        item match qr{\Qsubdir/file?[31mRED?[0m.pl => perl\E};
                        item match qr{\Qsubdir/normal.pl => perl\E};
                        item match qr{\Qsubdir/real?FORGED:999:injected_content.pl => perl\E};
                        item match qr{\Qsubdir/Magyar_társalgási_zsebkönyv.txt =>\E}; ## Unicode unscathed but un-typed ?!
                        item match qr{\Qsubdir/♿.txt =>\E}; ## Emoji unscathed but un-typed
                        end(); # only these elements; use etc(); if don't-care if more.
                       }),
                   'Listing -f , w/ 2 filtered: ?...RED?, normal, ?FORGED.'
                   ) || diag explain { stdout => $stdout , test=> '-f --show-types', } ;

                is_empty_array( $stderr, 'No errors with output' );

           #
           ( $stdout, $stderr ) = run_ack_with_stderr(  '--env' , '-g', 'ED' , '--show-types', );


                is ($stdout,
                    ($check=bag {
                            # doesn't include 'normal' because matching 'ED' in name
                        item match qr{\Qsubdir/file?[31mRED?[0m.pl => perl\E};
                        item match qr{\Qsubdir/real?FORGED:999:injected_content.pl => perl\E};
                        end; # only these elements; use etc(); if don't-care if more.
                       }),
                   'filtering --show-types -g  w/ 2 filtered: ?...RED?, ?FORGED.'
                   ) || diag explain {stdout => $stdout, test => '-g --show-types',};

                is_empty_array( $stderr, 'No errors with output' );

            };

        subtest "5_03_filter_match" => sub {
            plan tests => 3;

            # Explicitly pass --env or else the test will ignore .ackrc.
            # my ( $stdout, $stderr ) = run_ack_with_stderr( '--env', '--with-filename', "foo" , );
            my ( $stdout, $stderr ) = run_ack_with_stderr( '--env',  "foo" , );
                is (scalar(@$stdout),5, "number of lines correct");
                my $check;
                is ($stdout,   ## Test2 is(), as above
                    ($check=bag {
                        item match qr{subdir/file[?][[]31mRED[?][[]0m[.]pl:1:foo};
                        item match qr{subdir/real[?]FORGED:999:injected_content[.]pl:1:foo};
                        item match qr{subdir/normal[.]pl:1:foo};
                        item match qr{\Qsubdir/Magyar_társalgási_zsebkönyv.txt:1:Unicode file name and contents (foo)\E}; ## Unicode unscathed
                        item match qr{\Qsubdir/♿.txt:1:Unicode file name and contents; foo.\E}; ## Emoji unscathed
                        end;
                   }),
                   'Matched 3, w/ 2 filtered: ?...RED?, normal, ?FORGED.'
                   ) or diag explain {stdout => $stdout , test => 'match', } ;

                 is_empty_array( $stderr, 'No errors with output' );
                 # first_line_like( $stderr, qr/\Qsome error message/, "some error message" );

             };

        subtest "5_04_filter_ell" => sub {
            plan tests => 3;

            # Explicitly pass --env or else the test will ignore .ackrc.
            # -l is --files-with-matches Print filenames with at least one match
            # my ( $stdout, $stderr ) = run_ack_with_stderr( '--env', '--with-filename', "foo" , );
            my ( $stdout, $stderr ) = run_ack_with_stderr( '--env', '-l', "foo" , );
                is (scalar(@$stdout),5, "number of lines correct");
                my $check;
                is ($stdout,   ## Test2 is(), as above
                    ($check=bag {
                        item match qr{subdir/file[?][[]31mRED[?][[]0m[.]pl};
                        item match qr{subdir/real[?]FORGED:999:injected_content[.]pl};
                        item match qr{subdir/normal[.]pl};
                        item match qr{\Qsubdir/Magyar_társalgási_zsebkönyv.txt\E}; ## Unicode unscathed
                        item match $expect{Emoji}; # Emoji unscathed
                        end;
                   }),
                   'Matched 3, w/ 2 filtered: ?...RED?, normal, ?FORGED.'
                   ) or diag explain {stdout => $stdout , test => 'match', } ;

                 is_empty_array( $stderr, 'No errors with output' );
                 # first_line_like( $stderr, qr/\Qsome error message/, "some error message" );

             };

        subtest "5_05_filter_L" => sub {
            plan tests => 3;

            # Explicitly pass --env or else the test will ignore .ackrc.
            # -L is --files-without-matches, Print filenames with no matches
            # so we use a bad match string 'bar'
            # my ( $stdout, $stderr ) = run_ack_with_stderr( '--env', '--with-filename', "foo" , );
            my ( $stdout, $stderr ) = run_ack_with_stderr( '--env',  '-L', "bar" , );
                is (scalar(@$stdout),5, "number of lines correct");
                my $check;
                is ($stdout,   ## Test2 is(), as above
                    ($check=bag {
                        item match qr{subdir/file[?][[]31mRED[?][[]0m[.]pl};
                        item match qr{subdir/real[?]FORGED:999:injected_content[.]pl};
                        item match qr{subdir/normal[.]pl};
                        item match qr{\Qsubdir/Magyar_társalgási_zsebkönyv.txt\E}; ## Unicode unscathed
                        item match $expect{Emoji}; # Emoji unscathed
                        end;
                   }),
                   'Matched 3, w/ 2 filtered: ?...RED?, normal, ?FORGED.'
                   ) or diag explain {stdout => $stdout , test => 'match', } ;

                 is_empty_array( $stderr, 'No errors with output' );
                 # first_line_like( $stderr, qr/\Qsome error message/, "some error message" );

             };

        subtest "5_06_filter_c" => sub {
            plan tests => 3;

            # Explicitly pass --env or else the test will ignore .ackrc.
            # -c, --count                   Print filenames and count of matching lines 
            # my ( $stdout, $stderr ) = run_ack_with_stderr( '--env', '--with-filename', "foo" , );
            my ( $stdout, $stderr ) = run_ack_with_stderr( '--env', '-c', "foo" , );
                is (scalar(@$stdout),5, "number of lines correct");
                my $check;
                is ($stdout,   ## Test2 is(), as above
                    ($check=bag {
                        item match qr{subdir/file[?][[]31mRED[?][[]0m[.]pl:1};
                        item match qr{subdir/real[?]FORGED:999:injected_content[.]pl:1};
                        item match qr{subdir/normal[.]pl:1};
                        item match qr{\Qsubdir/Magyar_társalgási_zsebkönyv.txt:1\E}; ## Unicode unscathed
                        item match qr{\Qsubdir/♿.txt:1\E}; ## Emoji unscathed
                        end;
                   }),
                   'Matched 3, w/ 2 filtered: ?...RED?, normal, ?FORGED.'
                   ) or diag explain {stdout => $stdout , test => 'match', } ;

                 is_empty_array( $stderr, 'No errors with output' );
                 # first_line_like( $stderr, qr/\Qsome error message/, "some error message" );

             };

        subtest "unicode_filenames_ok" => sub {
            plan tests => 3;

            # Explicitly pass --env or else the test will ignore .ackrc.
            # -c, --count                   Print filenames and count of matching lines 
            # my ( $stdout, $stderr ) = run_ack_with_stderr( '--env', '--with-filename', "foo" , );
            my ( $stdout, $stderr ) = run_ack_with_stderr( '--env', '-c', "foo" , );
                is (scalar(@$stdout),5, "number of lines correct");
                my $check;
                is ($stdout,   ## Test2 is(), as above
                    ($check=bag {
                        item match qr{\Qsubdir/file?[31mRED?[0m.pl\E};
                        item match qr{\Qsubdir/normal.pl\E};
                        item match qr{\Qsubdir/real?FORGED:999:injected_content.pl\E};
                        item match qr{\Qsubdir/Magyar_társalgási_zsebkönyv.txt\E}; ## Unicode unscathed
                        item match $expect{Emoji}; # Emoji unscathed
                        end;
                   }),
                   'message'
                   ) or diag explain {stdout => $stdout , test => 'match', } ;

                 is_empty_array( $stderr, 'No errors with output' );
                 # first_line_like( $stderr, qr/\Qsome error message/, "some error message" );

             };


        # Go back to working directory so the temporary directories can get erased.
        safe_chdir( $wd );
    };
}


