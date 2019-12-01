package Util;

use 5.010001;

use parent 'Exporter';

use warnings;
use strict;

use Carp ();
use Cwd ();
use File::Next ();
use File::Spec ();
use File::Temp ();
use Scalar::Util qw( tainted );
use Term::ANSIColor ();
use Test::More;

our @EXPORT = qw(
    prep_environment
    create_globals
    clean_up_globals
    touch_ackrc

    has_io_pty
    is_windows
    is_cygwin

    is_empty_array
    is_nonempty_array

    first_line_like
    build_ack_invocation
    adjust_executable

    read_file
    write_file
    append_file
    create_tempfile
    touch

    reslash
    reslash_all
    windows_slashify

    run_cmd
    run_ack
    run_ack_with_stderr
    run_ack_interactive
    run_piped
    pipe_into_ack
    pipe_into_ack_with_stderr

    lists_match
    sets_match
    ack_lists_match
    ack_sets_match
    ack_error_matches

    untaint

    line_split
    colorize
    get_expected_options
    caret_X
    get_rc
    getcwd_clean
    filter_out_perldoc_noise
    make_unreadable

    safe_chdir
    safe_mkdir

    msg
    subtest_name
);

my $orig_wd;
my @temp_files; # We store temp files here to make sure they're properly reclaimed at interpreter shutdown.

sub prep_environment {
    my @ack_args   = qw( ACKRC ACK_PAGER HOME ACK_COLOR_MATCH ACK_COLOR_FILENAME ACK_COLOR_LINENO ACK_COLOR_COLNO );
    my @taint_args = qw( PATH CDPATH IFS ENV );
    delete @ENV{ @ack_args, @taint_args };

    if ( is_windows() ) {
        # To pipe, perl must be able to find cmd.exe, so add %SystemRoot%\system32 to the path.
        # See http://kstruct.com/2006/09/13/perl-taint-mode-and-cmdexe/
        $ENV{SystemRoot} =~ /([A-Z]:(\\[A-Z0-9_]+)+)/i or die 'Unrecognizable SystemRoot';
        my $system32_dir = File::Spec->catdir($1,'system32');
        $ENV{'PATH'} = $system32_dir;
    }

    $orig_wd = getcwd_clean();

    return;
}

sub is_windows {
    return $^O eq 'MSWin32';
}

sub is_cygwin {
    return ($^O eq 'cygwin' || $^O eq 'msys');
}

sub is_empty_array {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $aref = shift;
    my $msg  = shift;

    my $ok = defined($aref) && (ref($aref) eq 'ARRAY') && (scalar(@{$aref}) == 0);

    if ( !ok( $ok, $msg ) ) {
        diag( explain( $aref ) );
    }
    return $ok;
}

sub is_nonempty_array {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $aref = shift;
    my $msg  = shift;

    my $ok = defined($aref) && (ref($aref) eq 'ARRAY') && (scalar(@{$aref}) > 0);

    if ( !ok( $ok, $msg ) ) {
        diag( explain( $aref ) );
    }
    return $ok;
}

sub first_line_like {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $lines = shift;
    my $re    = shift;
    my $msg   = shift;

    my $ok = like( $lines->[0], $re, $msg );
    diag(explain($lines)) unless $ok;

    return $ok;
}


sub build_ack_invocation {
    my @args = @_;

    my $options;

    foreach my $arg ( @args ) {
        if ( ref($arg) eq 'HASH' ) {
            if ( $options ) {
                die 'You may not specify more than one options hash';
            }
            else {
                $options = $arg;
            }
        }
    }

    $options ||= {};

    if ( my $ackrc = $options->{ackrc} ) {
        if ( ref($ackrc) eq 'SCALAR' ) {
            my $temp_ackrc = create_tempfile( ${$ackrc} );
            push @temp_files, $temp_ackrc;
            $ackrc = $temp_ackrc->filename;
        }

        unshift @args, '--ackrc', $ackrc;
    }

    # The --noenv makes sure we don't pull in anything from the user
    #    unless explicitly specified in the test
    if ( !grep { /^--(no)?env$/ } @args ) {
        unshift( @args, '--noenv' );
    }

    if ( $ENV{'ACK_TEST_STANDALONE'} ) {
        unshift( @args, File::Spec->rel2abs( 'ack-standalone', $orig_wd ) );
    }
    else {
        unshift( @args, File::Spec->rel2abs( 'blib/script/ack', $orig_wd ) );
    }

    return @args;
}

# Use this instead of File::Slurp::read_file()
sub read_file {
    my $filename = shift;

    open( my $fh, '<', $filename ) or die "Can't read $filename: \n";
    my @lines = <$fh>;
    close $fh or die;

    return wantarray ? @lines : join( '', @lines );
}

# Use this instead of File::Slurp::write_file()
sub write_file {
    return _write_file( '>', 'create', @_ );
}

# Use this instead of File::Slurp::append_file()
sub append_file {
    return _write_file( '>>', 'append', @_ );
}

sub _write_file {
    my $op       = shift;
    my $verb     = shift;
    my $filename = shift;
    my @lines    = @_;

    open( my $fh, $op, $filename ) or die "Can't $verb $filename: \n";
    for my $line ( @lines ) {
        print {$fh} $line;
    }
    close $fh or die;

    return;
}

sub line_split {
    return split( /\n/, $_[0] );
}

sub reslash {
    return File::Next::reslash( shift );
}

sub reslash_all {
    return map { File::Next::reslash( $_ ) } @_;
}

sub run_ack {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my @args = @_;

    my ($stdout, $stderr) = run_ack_with_stderr( @args );
    @args = grep { ref ne 'HASH' } @args;

    if ( $TODO ) {
        fail( q{Automatically fail stderr check for TODO tests.} );
    }
    else {
        is_empty_array( $stderr, "Should have no output to stderr: ack @args" );
    }

    return wantarray ? @{$stdout} : join( "\n", @{$stdout} );
}

{ # scope for $ack_return_code;

# Capture return code.
our $ack_return_code;

# Run the given command, assuming that the command was created with
# build_ack_invocation (and thus writes its STDERR to $catcherr_file).
#
# Sets $ack_return_code and unlinks the $catcherr_file.
#
# Returns chomped STDOUT and STDERR as two array refs.
sub run_cmd {
    my ( @cmd ) = @_;

    my $options = {};

    foreach my $arg (@cmd) {
        if ( ref($arg) eq 'HASH' ) {
            $options = $arg;
        }
    }
    @cmd = grep { ref ne 'HASH' } @cmd;

    _record_option_coverage(@cmd);

    _check_command_for_taintedness( @cmd );

    my ( @stdout, @stderr );

    if ( is_windows() ) {
        ## no critic ( InputOutput::ProhibitTwoArgOpen )
        ## no critic ( InputOutput::ProhibitBarewordFileHandles )
        require Win32::ShellQuote;
        # Capture stderr & stdout output into these files (only on Win32).
        my $tempdir = File::Temp->newdir;
        my $catchout_file = File::Spec->catfile( $tempdir->dirname, 'stdout.log' );
        my $catcherr_file = File::Spec->catfile( $tempdir->dirname, 'stderr.log' );

        open(SAVEOUT, '>&STDOUT') or die "Can't dup STDOUT: $!";
        open(SAVEERR, '>&STDERR') or die "Can't dup STDERR: $!";
        open(STDOUT, '>', $catchout_file) or die "Can't open $catchout_file: $!";
        open(STDERR, '>', $catcherr_file) or die "Can't open $catcherr_file: $!";
        my $cmd = Win32::ShellQuote::quote_system_string(@cmd);
        if ( my $input = $options->{input} ) {
            my $input_command = Win32::ShellQuote::quote_system_string(@{$input});
            $cmd = "$input_command | $cmd";
        }
        system( $cmd );
        close STDOUT;
        close STDERR;
        open(STDOUT, '>&SAVEOUT') or die "Can't restore STDOUT: $!";
        open(STDERR, '>&SAVEERR') or die "Can't restore STDERR: $!";
        close SAVEOUT;
        close SAVEERR;
        @stdout = read_file($catchout_file);
        @stderr = read_file($catcherr_file);
    }
    else {
        my ( $stdout_read, $stdout_write );
        my ( $stderr_read, $stderr_write );

        pipe $stdout_read, $stdout_write
            or die "Unable to create pipe: $!";

        pipe $stderr_read, $stderr_write
            or die "Unable to create pipe: $!";

        my $pid = fork();
        if ( $pid == -1 ) {
            die "Unable to fork: $!";
        }

        if ( $pid ) {
            close $stdout_write;
            close $stderr_write;

            while ( $stdout_read || $stderr_read ) {
                my $rin = '';

                vec( $rin, fileno($stdout_read), 1 ) = 1 if $stdout_read;
                vec( $rin, fileno($stderr_read), 1 ) = 1 if $stderr_read;

                select( $rin, undef, undef, undef );

                if ( $stdout_read && vec( $rin, fileno($stdout_read), 1 ) ) {
                    my $line = <$stdout_read>;

                    if ( defined( $line ) ) {
                        push @stdout, $line;
                    }
                    else {
                        close $stdout_read;
                        undef $stdout_read;
                    }
                }

                if ( $stderr_read && vec( $rin, fileno($stderr_read), 1 ) ) {
                    my $line = <$stderr_read>;

                    if ( defined( $line ) ) {
                        push @stderr, $line;
                    }
                    else {
                        close $stderr_read;
                        undef $stderr_read;
                    }
                }
            }

            waitpid $pid, 0;
        }
        else {
            close $stdout_read;
            close $stderr_read;

            if (my $input = $options->{input}) {
                _check_command_for_taintedness( @{$input} );
                open STDIN, '-|', @{$input} or die "Can't open STDIN: $!";
            }

            open STDOUT, '>&', $stdout_write or die "Can't open STDOUT: $!";
            open STDERR, '>&', $stderr_write or die "Can't open STDERR: $!";

            exec @cmd;
        }
    } # end else not Win32

    my ($sig,$core,$rc) = (($? & 127), ($? & 128), ($? >> 8));  ## no critic ( Bangs::ProhibitBitwiseOperators Variables::ProhibitUnusedVarsStricter )
    $ack_return_code = $rc;
    ## XXX what to do with $core or $sig?

    chomp @stdout;
    chomp @stderr;

    return ( \@stdout, \@stderr );
}


sub get_rc {
    return $ack_return_code;
}

} # scope for $ack_return_code

sub run_ack_with_stderr {
    my @args = @_;

    @args = adjust_executable( build_ack_invocation( @args ) );

    return run_cmd( @args );
}


sub run_piped {
    my $lhs_args = shift;
    my $rhs_args = shift;

    my $stdout;
    my $stderr;

    my ( $stdout_read, $stdout_write );
    my ( $stderr_read, $stderr_write );
    my ( $lhs_rhs_read, $lhs_rhs_write );

    pipe( $stdout_read, $stdout_write );
    pipe( $stderr_read, $stderr_write );
    pipe( $lhs_rhs_read, $lhs_rhs_write );

    my $lhs_pid;
    my $rhs_pid;

    $lhs_pid = fork();

    if ( !defined($lhs_pid) ) {
        die 'Unable to fork';
    }

    if ( $lhs_pid ) {
        $rhs_pid = fork();

        if ( !defined($rhs_pid) ) {
            kill TERM => $lhs_pid;
            waitpid $lhs_pid, 0;
            die 'Unable to fork';
        }
    }

    if ( $rhs_pid ) { # parent
        close $stdout_write;
        close $stderr_write;
        close $lhs_rhs_write;
        close $lhs_rhs_read;

        _do_parent(
            stdout_read  => $stdout_read,
            stderr_read  => $stderr_read,
            stdout_lines => ($stdout = []),
            stderr_lines => ($stderr = []),
        );

        waitpid $lhs_pid, 0;
        waitpid $rhs_pid, 0;
    }
    elsif ( $lhs_pid ) { # right-hand-side child
        close $stdout_read;
        close $stderr_read;
        close $stderr_write;
        close $lhs_rhs_write;

        open STDIN, '<&', $lhs_rhs_read or die "Can't open: $!";
        open STDOUT, '>&', $stdout_write or die "Can't open: $!";
        close STDERR;

        exec @{$rhs_args};
    }
    else { # left-hand side child
        close $stdout_read;
        close $stdout_write;
        close $lhs_rhs_read;
        close $stderr_read;

        open STDOUT, '>&', $lhs_rhs_write or die "Can't open: $!";
        open STDERR, '>&', $stderr_write or die "Can't open: $!";
        close STDIN;

        exec @{$lhs_args};
    }

    return ($stdout,$stderr);
}


sub _do_parent {
    my %params = @_;

    my ( $stdout_read, $stderr_read, $stdout_lines, $stderr_lines ) =
        @params{qw/stdout_read stderr_read stdout_lines stderr_lines/};

    while ( $stdout_read || $stderr_read ) {
        my $rin = '';

        vec( $rin, fileno($stdout_read), 1 ) = 1 if $stdout_read;
        vec( $rin, fileno($stderr_read), 1 ) = 1 if $stderr_read;

        select( $rin, undef, undef, undef );

        if ( $stdout_read && vec( $rin, fileno($stdout_read), 1 ) ) {
            my $line = <$stdout_read>;

            if ( defined( $line ) ) {
                push @{$stdout_lines}, $line;
            }
            else {
                close $stdout_read;
                undef $stdout_read;
            }
        }

        if ( $stderr_read && vec( $rin, fileno($stderr_read), 1 ) ) {
            my $line = <$stderr_read>;

            if ( defined( $line ) ) {
                push @{$stderr_lines}, $line;
            }
            else {
                close $stderr_read;
                undef $stderr_read;
            }
        }
    }

    chomp @{$stdout_lines};
    chomp @{$stderr_lines};

    return;
}



# Pipe into ack and return STDOUT and STDERR as array refs.
sub pipe_into_ack_with_stderr {
    my $input = shift;
    my @args = @_;

    if ( ref($input) eq 'SCALAR' ) {
        # We could easily do this without temp files, but that would take
        # slightly more time than I'm willing to spend on this right now.
        my $tempfile = create_tempfile( ${$input} );
        $input = $tempfile->filename;
    }

    return run_ack_with_stderr(@args, {
        # Use Perl since we don't know that 'cat' will exist.
        input => [caret_X(), '-pe1', $input],
    });
}

# Pipe into ack and return STDOUT as array, for arguments see pipe_into_ack_with_stderr.
sub pipe_into_ack {
    my ($stdout, undef) = pipe_into_ack_with_stderr( @_ );
    return @{$stdout};
}


# Use this one if order is important.
sub lists_match {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my @actual   = @{+shift};
    my @expected = @{+shift};
    my $msg      = _check_message( shift );

    # Normalize all the paths
    for my $path ( @expected, @actual ) {
        $path = File::Next::reslash( $path );
    }

    return subtest subtest_name( $msg ) => sub {
        plan tests => 1;

        my $ok;
        my $rc = eval 'use Test::Differences; 1;';
        if ( $rc ) {
            $ok = eq_or_diff( [@actual], [@expected], $msg );
        }
        else {
            $ok = is_deeply( [@actual], [@expected], $msg );
        }

        if ( !$ok ) {
            diag( explain( actual => [@actual], expected => [@expected] ) );
        }

        return $ok;
    };
}

sub ack_lists_match {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $args     = shift;
    my $expected = shift;
    my $msg      = _check_message( shift );

    my @args = @{$args};
    return subtest subtest_name( $msg, @args ) => sub {
        plan tests => 2;

        my @results = run_ack( @args );
        my $ok = lists_match( \@results, $expected, $msg );

        return $ok;
    };
}

# Use this one if you don't care about order of the lines.
sub sets_match {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my @actual   = @{+shift};
    my @expected = @{+shift};
    my $msg      = _check_message( shift );

    return subtest subtest_name( $msg ) => sub {
        plan tests => 1;

        return lists_match( [sort @actual], [sort @expected], $msg );
    };
}

sub ack_sets_match {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $args     = shift;
    my $expected = shift;
    my $msg      = _check_message( shift );

    my @args = @{$args};

    return subtest subtest_name( $msg, @args ) => sub {
        plan tests => 2;

        my @results = run_ack( @args );

        return sets_match( \@results, $expected, $msg );
    };
}


sub ack_error_matches {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $args     = shift;
    my $expected = shift;
    my $msg      = shift;

    return subtest subtest_name( $msg, $args, $expected ) => sub {
        plan tests => 4;

        my ( $stdout, $stderr ) = run_ack_with_stderr( @{$args} );
        isnt( get_rc(), 0, 'Nonzero error' );
        is_empty_array( $stdout, 'No normal output' );
        is( scalar @{$stderr}, 1, 'Just one error' );
        like( $stderr->[0], $expected, 'Error matches' );
    };
}


sub _record_option_coverage {
    my ( @command_line ) = @_;

    return unless $ENV{ACK_OPTION_COVERAGE};
    return if $ENV{ACK_TEST_STANDALONE}; # We don't need to record the second time around.

    my $record_options = File::Spec->catfile( $orig_wd, 'dev', 'record-options' );

    my $perl = caret_X();
    if ( @command_line == 1 ) {
        my $command_line = $command_line[0];

        # strip the command line up until 'ack' is found
        $command_line =~ s/^.*ack\b//;

        $command_line = "$perl $record_options $command_line";

        system $command_line;
    }
    else {
        while ( @command_line && $command_line[0] !~ /ack/ ) {
            shift @command_line;
        }
        shift @command_line; # get rid of 'ack' itself
        unshift @command_line, $perl, $record_options;

        system @command_line;
    }

    return;
}

=head2 colorize( $big_long_string )

Turns a multi-line input string into its corresponding array of lines, with colorized transformations.

    <text> gets turned to filename color.
    {text} gets turned to line number color.
    (text) gets turned to highlight color.

=cut

sub colorize {
    my $input = shift;

    my @lines = line_split( $input );

    for my $line ( @lines ) {
        # File name
        $line =~ s/<(.+?)>/Term::ANSIColor::colored($1, 'bold green')/eg;

        # Line number
        $line =~ s/\{(.+?)\}/Term::ANSIColor::colored($1, 'bold yellow')/eg;

        # Matches
        my $n;
        $n += $line =~ s/\((.+?)\)/Term::ANSIColor::colored($1, 'black on_yellow')/eg;

        $line .= "\e[0m\e[K" if $n;
    }

    return @lines;
}


BEGIN {
    my $has_io_pty = eval {
        require IO::Pty;
        1;
    };

    sub has_io_pty {
        return $has_io_pty;
    }

    if ($has_io_pty) {
        no strict 'refs';
        # This function fools ack into thinking it is not writing to a pipe. This lets us test some of ack's default
        # behaviors, like defaulting to --break/--heading in interactive mode, but --nobreak/--noheading when writing
        # to a pipe.
        *run_ack_interactive = sub {
            my ( @args) = @_;

            my @cmd = build_ack_invocation(@args);
            @cmd    = grep { ref ne 'HASH' } @cmd;

            _record_option_coverage(@cmd);

            @cmd = adjust_executable( @cmd );

            my $pty = IO::Pty->new;

            my $pid = fork;

            if ( $pid ) {
                $pty->close_slave();
                $pty->set_raw();

                if ( wantarray ) {
                    my @lines;

                    while ( <$pty> ) {
                        chomp;
                        push @lines, $_;
                    }
                    close $pty;
                    waitpid $pid, 0;
                    return @lines;
                }
                else {
                    my $output = '';

                    while ( <$pty> ) {
                        $output .= $_;
                    }
                    close $pty;
                    waitpid $pid, 0;
                    return $output;
                }
            }
            else {
                $pty->make_slave_controlling_terminal();
                my $slave = $pty->slave();
                if ( -t *STDIN ) {
                    # Is there something we can fall back on? Maybe re-opening /dev/console?
                    $slave->clone_winsize_from(\*STDIN);
                }
                $slave->set_raw();

                open STDIN,  '<&', $slave->fileno() or die "Can't open: $!";
                open STDOUT, '>&', $slave->fileno() or die "Can't open: $!";
                open STDERR, '>&', $slave->fileno() or die "Can't open: $!";

                close $slave;

                exec @cmd;
            }
        };
    }
    else {
        no strict 'refs';
        require Test::More;

        *run_ack_interactive = sub {
            local $Test::Builder::Level = $Test::Builder::Level + 1;
            Test::More::fail(<<'HERE');
Your system doesn't seem to have IO::Pty, and the developers
forgot to check in this test file.  Please file a bug report
at https://github.com/beyondgrep/ack3/issues with the name of
the file that generated this failure.
HERE
        };
    }
}

# This should not be treated as a complete list of the available
# options, but it's complete enough to rely on until we find a
# more elegant way to generate this list.
sub get_expected_options {
    return (
        '--ackrc',
        '--after-context',
        '--bar',
        '--before-context',
        '--break',
        '--cathy',
        '--color',
        '--color-filename',
        '--color-lineno',
        '--color-match',
        '--colour',
        '--column',
        '--context',
        '--count',
        '--create-ackrc',
        '--dump',
        '--env',
        '--files-from',
        '--files-with-matches',
        '--files-without-matches',
        '--filter',
        '--flush',
        '--follow',
        '--group',
        '--heading',
        '--help',
        '--help-types',
        '--help-colors',
        '--help-rgb-colors',
        '--ignore-ack-defaults',
        '--ignore-case',
        '--ignore-dir',
        '--ignore-directory',
        '--ignore-file',
        '--invert-match',
        '--literal',
        '--man',
        '--match',
        '--max-count',
        '--no-filename',
        '--no-recurse',
        '--nobreak',
        '--nocolor',
        '--nocolour',
        '--nocolumn',
        '--noenv',
        '--nofilter',
        '--nofollow',
        '--nogroup',
        '--noheading',
        '--noignore-dir',
        '--noignore-directory',
        '--nopager',
        '--nosmart-case',
        '--output',
        '--pager',
        '--passthru',
        '--print0',
        '--recurse',
        '--show-types',
        '--smart-case',
        '--sort-files',
        '--thpppt',
        '--type',
        '--type-add',
        '--type-del',
        '--type-set',
        '--version',
        '--with-filename',
        '--word-regexp',
        '-1',
        '-A',
        '-B',
        '-C',
        '-H',
        '-L',
        '-Q',
        '-R',
        '-S',
        '-c',
        '-f',
        '-g',
        '-h',
        '-i',
        '-l',
        '-m',
        '-n',
        '-o',
        '-r',
        '-s',
        '-v',
        '-w',
        '-x',
    );
}


# This is just a handy diagnostic tool.
sub _check_command_for_taintedness {
    my @args = @_;

    my @tainted = grep { tainted( $_ ) } @args;

    if ( @tainted ) {
        die "Can't execute this command because of taintedness:\nAll args: @args\nTainted:  @tainted\n";
    }

    return;
}


sub untaint {
    my ( $s ) = @_;

    $s =~ /\A(.*)\z/ or die 'Somehow unable to untaint';
    return $1;
}


sub caret_X {
    return untaint( $^X ); # XXX How is it $^X can be tainted?  We should not have to untaint it.
}


sub getcwd_clean {
    my $cwd = Cwd::getcwd();
    $cwd =~ /./ or die 'cwd is empty';
    return untaint( $cwd ); # XXX How is it that Cwd is tainted?
}


sub windows_slashify {
    my $str = shift;

    $str =~ s{/}{\\}g;

    return $str;
}


sub create_tempfile {
    my @lines = @_;

    my $tempfile = File::Temp->new();
    print {$tempfile} join( "\n", @lines );
    close $tempfile or die $!;

    return $tempfile;
}


sub touch {
    my $filename = shift;

    open my $fh, '>>', $filename or die "Unable to append to $filename: $!";
    close $fh or die $!;

    return;
}


sub _check_message {
    my $msg = shift;

    if ( !defined( $msg ) ) {
        my (undef,undef,undef,$sub) = caller(1);
        die "You must pass a message to $sub";
    }

    return $msg;
}

=head2 msg( [@args] )

Returns a basic diagnostic string based on the arguments passed in.
It is not strictly accurate, like something from Data::Dumper, but is
meant to balance accuracy of diagnostics with ease.

    msg( 'User codes', [ 'ABC', '123' ], undef, { foo => bar } )

will return

    'User codes, [ABC, 123], undef, { foo => bar }'

=cut

sub msg {
    my @args = @_;

    my @disp;
    for my $i ( @args ) {
        if ( !defined($i) ) {
            push( @disp, 'undef' );
        }
        elsif ( ref($i) eq 'HASH' ) {
            push( @disp, join( ', ', map { "$_=>" . ($i->{$_} // 'undef') } sort keys %{$i} ) );
        }
        elsif ( ref($i) eq 'ARRAY' ) {
            push( @disp, '[' . join( ', ', map { $_ // 'undef' } @{$i} ) . ']' );
        }
        else {
            push( @disp, "$i" );
        }
    }

    return join( ', ', @disp );
}


=head2 subtest_name( [@args] )

Returns a string for a name for a subtest, including the name of the
subroutine and basic string representations of the arguments.

This makes it easy for you to keep track of the important args passed into
the test, and include the function name without repetitively typing it.

    sub test_whatever {
        my $user = shift;
        my $foo  = shift;
        my $bar  = shift;
        my $msg  = shfit;

        return subtest subtest_name( $foo, $bar, $msg ) => sub {
            ....
    }

    test_whatever( 17, { this => 'that', other => undef }, 'Try it again without NYP' );

This will then give you TAP output like this:

    # Subtest: main::test_whatever( 17, {other=>undef, this=>that}, Try it again without NYP )

Note that in the example, we didn't pass C<$user> because it wasn't
interesting to debugging.

=cut

sub subtest_name {
    my @args = @_;

    my (undef, undef, undef, $sub) = caller(1);

    ($sub ne '') or die 'subtest_name() can only be called inside a function';

    return $sub unless @args;

    my $disp = msg( @args );

    return "$sub( $disp )";
}


# The tests blow up on Windows if the global files don't exist,
# so here we create them if they don't, keeping track of the ones
# we make so we can delete them later.

my @created_global_files;

sub create_globals {
    my @files;

    if ( is_windows() ) {
        require Win32;

        my @paths = map {
            File::Spec->catfile( Win32::GetFolderPath( $_ ), 'ackrc' )
        } (
            Win32::CSIDL_COMMON_APPDATA(),
            Win32::CSIDL_APPDATA()
        );

        # Brute-force untaint the paths we built so they can be unlinked later.
        @files = map { /(.+)/ ? $1 : die } @paths;
    }
    else {
        @files = ( '/etc/ackrc' );
    }

    if ( is_windows() || is_cygwin() ) {
        for my $filename ( @files ) {
            if ( not -e $filename ) {
                touch_ackrc( $filename );
                push @created_global_files, $filename;
            }
        }
    }

    return @files;
}


sub clean_up_globals {
    foreach my $filename ( @created_global_files ) {
        unlink $filename or warn "Couldn't unlink $filename: $!";
    }

    return;
}


sub touch_ackrc {
    my $filename = shift or die;
    write_file( $filename, () );

    return;
}


sub safe_chdir {
    my $dir = shift;

    CORE::chdir( $dir ) or die "Can't chdir to $dir: $!";

    return;
}


sub safe_mkdir {
    my $dir = shift;

    CORE::mkdir( $dir ) or die "Can't mkdir $dir: $!";

    return;
}


sub filter_out_perldoc_noise {
    my $stderr = shift;

    # Don't worry if man complains about long lines, or if the terminal doesn't handle Unicode.
    $stderr = [
        grep {
            !m{
                can't\ break\ line
                |
                Wide\ character\ in\ print
                |
                Unknown\ escape\ E<0x[[:xdigit:]]+>
                |
                stdin\ isn't\ a\ terminal
                |
                Inappropriate\ ioctl\ for\ device
            }x
        } @{$stderr}
    ];

    return $stderr;
}


sub make_unreadable {
    my $file = shift;

    my $old_mode;
    my $new_mode;
    my $error;

    # Change permissions of this file to unreadable.
    my @old_stat = stat($file);
    if ( !@old_stat ) {
        $error = "Unable to stat $file: $!";
    }
    else {
        $old_mode = $old_stat[2];

        my $nfiles = chmod 0000, $file;
        if ( !$nfiles ) {
            $error = "Unable to chmod $file: $!";
        }
        else {
            my @new_stat = stat($file);
            if ( !@new_stat ) {
                $error = "Unable to stat $file after chmod: $!";
            }
            else {
                $new_mode = $new_stat[2];

                if ( $old_mode eq $new_mode ) {
                    $error = "chmod did not modify modify ${file}'s permissions";
                }
                elsif ( -r $file ) {
                    $error = "File $file is still readable despite our attempts to changes its permissions";
                }
            }
        }
    }

    return ($old_mode, $error);
}


sub adjust_executable {
    my @cmd = @_;

    my $perl = caret_X();

    if ( $ENV{'ACK_TEST_STANDALONE'} ) {
        unshift( @cmd, $perl );
    }
    else {
        unshift( @cmd, $perl, "-Mblib=$orig_wd" );
    }

    return @cmd;
}


1;
