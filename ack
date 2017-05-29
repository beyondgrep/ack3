#!/usr/bin/perl

use strict;
use warnings;
our $VERSION = '2.999_01'; # Check https://beyondgrep.com/ for updates

use 5.010001;
use Getopt::Long 2.38 ();
use Carp 1.04 ();

use File::Spec ();
use File::Next ();

use App::Ack ();
use App::Ack::ConfigLoader ();
use App::Ack::File ();
use App::Ack::Files ();

use App::Ack::Filter ();
use App::Ack::Filter::Default;
use App::Ack::Filter::Extension;
use App::Ack::Filter::FirstLineMatch;
use App::Ack::Filter::Inverse;
use App::Ack::Filter::Is;
use App::Ack::Filter::IsPath;
use App::Ack::Filter::Match;
use App::Ack::Filter::Collection;

# Global command-line options
our $opt_after_context;
our $opt_before_context;
our $opt_break;
our $opt_color;
our $opt_column;
our $opt_count;
our $opt_f;
our $opt_g;
our $opt_heading;
our $opt_L;
our $opt_l;
our $opt_lines;
our $opt_m;
our $opt_output;
our $opt_passthru;
our $opt_print0;
our $opt_proximate;
our $opt_regex;
our $opt_show_filename;
our $opt_u;
our $opt_v;

# Flag if we need any context tracking.
our $is_tracking_context;

MAIN: {
    $App::Ack::ORIGINAL_PROGRAM_NAME = $0;
    $0 = join(' ', 'ack', $0);
    if ( $App::Ack::VERSION ne $main::VERSION ) {
        App::Ack::die( "Program/library version mismatch\n\t$0 is $main::VERSION\n\t$INC{'App/Ack.pm'} is $App::Ack::VERSION" );
    }

    # Do preliminary arg checking;
    my $env_is_usable = 1;
    for my $arg ( @ARGV ) {
        last if ( $arg eq '--' );

        # Get the --thpppt, --bar, --cathy checking out of the way.
        $arg =~ /^--th[pt]+t+$/ and App::Ack::thpppt($arg);
        $arg eq '--bar'         and App::Ack::ackbar();
        $arg eq '--cathy'       and App::Ack::cathy();

        # See if we want to ignore the environment. (Don't tell Al Gore.)
        $arg eq '--env'         and $env_is_usable = 1;
        $arg eq '--noenv'       and $env_is_usable = 0;
    }

    if ( !$env_is_usable ) {
        my @keys = ( 'ACKRC', grep { /^ACK_/ } keys %ENV );
        delete @ENV{@keys};
    }

    # Load colors
    my $modules_loaded_ok = eval 'use Term::ANSIColor 1.10 (); 1;';
    if ( $modules_loaded_ok && $App::Ack::is_windows ) {
        $modules_loaded_ok = eval 'use Win32::Console::ANSI; 1;';
    }
    if ( $modules_loaded_ok ) {
        $ENV{ACK_COLOR_MATCH}    ||= 'black on_yellow';
        $ENV{ACK_COLOR_FILENAME} ||= 'bold green';
        $ENV{ACK_COLOR_LINENO}   ||= 'bold yellow';
    }

    Getopt::Long::Configure('default', 'no_auto_help', 'no_auto_version');
    Getopt::Long::Configure('pass_through', 'no_auto_abbrev');
    Getopt::Long::GetOptions(
        'help'       => sub { App::Ack::show_help(); exit; },
        'version'    => sub { App::Ack::print( App::Ack::get_version_statement() ); exit; },
        'man'        => sub { App::Ack::show_docs( 'Manual' ); }, # man/faq/cookbook all exit.
        'faq'        => sub { App::Ack::show_docs( 'FAQ' ); },
        'cookbook'   => sub { App::Ack::show_docs( 'Cookbook' ); },
    );
    Getopt::Long::Configure('default', 'no_auto_help', 'no_auto_version');

    if ( !@ARGV ) {
        App::Ack::show_help();
        exit 1;
    }

    my @arg_sources = App::Ack::ConfigLoader::retrieve_arg_sources();

    my $opt = App::Ack::ConfigLoader::process_args( @arg_sources );

    $opt_after_context  = $opt->{after_context};
    $opt_before_context = $opt->{before_context};
    $opt_break          = $opt->{break};
    $opt_proximate      = $opt->{proximate};
    $opt_color          = $opt->{color};
    $opt_column         = $opt->{column};
    $opt_count          = $opt->{count};
    $opt_f              = $opt->{f};
    $opt_g              = $opt->{g};
    $opt_heading        = $opt->{heading};
    $opt_L              = $opt->{L};
    $opt_l              = $opt->{l};
    $opt_lines          = $opt->{lines};
    $opt_m              = $opt->{m};
    $opt_output         = $opt->{output};
    $opt_passthru       = $opt->{passthru};
    $opt_print0         = $opt->{print0};
    $opt_regex          = $opt->{regex};
    $opt_show_filename  = $opt->{show_filename};
    $opt_u              = $opt->{u};
    $opt_v              = $opt->{v};

    $App::Ack::report_bad_filenames = !$opt->{s};

    if ( !defined($opt_color) && !$opt_g ) {
        my $windows_color = 1;
        if ( $App::Ack::is_windows ) {
            $windows_color = eval { require Win32::Console::ANSI; };
        }
        $opt_color = !App::Ack::output_to_pipe() && $windows_color;
    }
    if ( not defined $opt_heading and not defined $opt_break  ) {
        $opt_heading = $opt_break = $opt->{break} = !App::Ack::output_to_pipe();
    }

    if ( defined($opt->{H}) || defined($opt->{h}) ) {
        $opt_show_filename = $opt->{show_filename} = $opt->{H} && !$opt->{h};
    }

    if ( my $output = $opt_output ) {
        $output        =~ s{\\}{\\\\}g;
        $output        =~ s{"}{\\"}g;
        $opt_output = qq{"$output"};
    }

    # Set up file filters.
    my $files;
    if ( $App::Ack::is_filter_mode && !$opt->{files_from} ) { # probably -x
        $files     = App::Ack::Files->from_stdin();
        $opt_regex = shift @ARGV if not defined $opt_regex;
        $opt_regex = $opt->{regex} = build_regex( $opt_regex, $opt );
    }
    else {
        if ( $opt_f || $opt_lines ) {
            if ( $opt_regex ) {
                App::Ack::warn( "regex ($opt_regex) specified with -f or --lines" );
                App::Ack::exit_from_ack( 0 );
            }
        }
        else {
            $opt_regex = shift @ARGV if not defined $opt_regex;
            $opt_regex = $opt->{regex} = build_regex( $opt_regex, $opt );
        }
        if ( $opt_regex && $opt_regex =~ /\n/ ) {
            App::Ack::exit_from_ack( 0 );
        }
        my @start;
        if ( not defined $opt->{files_from} ) {
            @start = @ARGV;
        }
        if ( !exists($opt->{show_filename}) ) {
            unless(@start == 1 && !(-d $start[0])) {
                $opt_show_filename = $opt->{show_filename} = 1;
            }
        }

        if ( defined $opt->{files_from} ) {
            $files = App::Ack::Files->from_file( $opt, $opt->{files_from} );
            exit 1 unless $files;
        }
        else {
            @start = ('.') unless @start;
            foreach my $target (@start) {
                if ( !-e $target && $App::Ack::report_bad_filenames) {
                    App::Ack::warn( "$target: No such file or directory" );
                }
            }

            $opt->{file_filter}    = _compile_file_filter($opt, \@start);
            $opt->{descend_filter} = _compile_descend_filter($opt);

            $files = App::Ack::Files->from_argv( $opt, \@start );
        }
    }
    App::Ack::set_up_pager( $opt->{pager} ) if defined $opt->{pager};

    my $ors        = $opt_print0 ? "\0" : "\n";
    my $only_first = $opt->{1};

    my $nmatches    = 0;
    my $total_count = 0;

    set_up_line_context();

FILES:
    while ( my $file = $files->next ) {
        if ($is_tracking_context) {
            set_up_line_context_for_file();
        }

        # ack -f
        if ( $opt_f ) {
            if ( $opt->{show_types} ) {
                App::Ack::show_types( $file, $ors );
            }
            else {
                App::Ack::print( $file->name, $ors );
            }
            ++$nmatches;
            last FILES if defined($opt_m) && $nmatches >= $opt_m;
        }
        # ack -g
        elsif ( $opt_g ) {
            if ( $opt->{show_types} ) {
                App::Ack::show_types( $file, $ors );
            }
            else {
                local $opt_show_filename = 0; # XXX Why is this local?

                print_line_with_options( '', $file->name, 0, $ors );
            }
            ++$nmatches;
            last FILES if defined($opt_m) && $nmatches >= $opt_m;
        }
        # ack --lines
        elsif ( $opt_lines ) {
            my %line_numbers;
            foreach my $line ( @{ $opt_lines } ) {
                my @lines             = split /,/, $line;
                @lines                = map {
                    /^(\d+)-(\d+)$/
                        ? ( $1 .. $2 )
                        : $_
                } @lines;
                @line_numbers{@lines} = (1) x @lines;
            }

            my $filename = $file->name;

            local $opt_color = 0;

            iterate( $file, sub {
                chomp;

                if ( $line_numbers{$.} ) {
                    print_line_with_context( $filename, $_, $. );
                }
                elsif ( $opt_passthru ) {
                    print_line_with_options( $filename, $_, $., ':' );
                }
                elsif ( $is_tracking_context ) {
                    print_line_if_context( $filename, $_, $., '-' );
                }
                return 1;
            });
        }
        # ack -c
        elsif ( $opt_count ) {
            my $matches_for_this_file = count_matches_in_file( $file );

            if ( not $opt_show_filename ) {
                $total_count += $matches_for_this_file;
                next FILES;
            }

            if ( !$opt_l || $matches_for_this_file > 0) {
                if ( $opt_show_filename ) {
                    App::Ack::print( $file->name, ':', $matches_for_this_file, $ors );
                }
                else {
                    App::Ack::print( $matches_for_this_file, $ors );
                }
            }
        }
        # ack -l, ack -L
        elsif ( $opt_l || $opt_L ) {
            my $is_match = file_has_match( $file );

            if ( $opt_L ? !$is_match : $is_match ) {
                App::Ack::print( $file->name, $ors );
                ++$nmatches;

                last FILES if $only_first;
                last FILES if defined($opt_m) && $nmatches >= $opt_m;
            }
        }
        # Normal match-showing ack
        else {
            $nmatches += print_matches_in_file( $file, $opt );
            if ( $nmatches && $only_first ) {
                last FILES;
            }
        }
    }

    if ( $opt_count && !$opt_show_filename ) {
        App::Ack::print( $total_count, "\n" );
    }

    close $App::Ack::fh;

    App::Ack::exit_from_ack( $nmatches );
}

# End of MAIN

sub _compile_descend_filter {
    my ( $opt ) = @_;

    my $idirs = 0;
    my $dont_ignore_dirs = 0;

    for my $filter (@{$opt->{idirs} || []}) {
        if ($filter->is_inverted()) {
            $dont_ignore_dirs++;
        }
        else {
            $idirs++;
        }
    }

    # If we have one or more --noignore-dir directives, we can't ignore
    # entire subdirectory hierarchies, so we return an "accept all"
    # filter and scrutinize the files more in _compile_file_filter.
    return if $dont_ignore_dirs;
    return unless $idirs;

    $idirs = $opt->{idirs};

    return sub {
        my $file = App::Ack::File->new($File::Next::dir);
        return !grep { $_->filter($file) } @{$idirs};
    };
}

sub _compile_file_filter {
    my ( $opt, $start ) = @_;

    my $ifiles_filters = $opt->{ifiles};

    my $filters         = $opt->{'filters'} || [];
    my $direct_filters = App::Ack::Filter::Collection->new();
    my $inverse_filters = App::Ack::Filter::Collection->new();

    foreach my $filter (@{$filters}) {
        if ($filter->is_inverted()) {
            # We want to check if files match the uninverted filters
            $inverse_filters->add($filter->invert());
        }
        else {
            $direct_filters->add($filter);
        }
    }

    my %is_member_of_starting_set = map { (get_file_id($_) => 1) } @{$start};

    my @ignore_dir_filter = @{$opt->{idirs} || []};
    my @is_inverted       = map { $_->is_inverted() } @ignore_dir_filter;
    # This depends on InverseFilter->invert returning the original filter (for optimization).
    @ignore_dir_filter         = map { $_->is_inverted() ? $_->invert() : $_ } @ignore_dir_filter;
    my $dont_ignore_dir_filter = grep { $_ } @is_inverted;
    my $previous_dir = '';
    my $previous_dir_ignore_result;

    return sub {
        if ( $opt_g ) {
            if ( $File::Next::name =~ /$opt_regex/ && $opt_v ) {
                return 0;
            }
            if ( $File::Next::name !~ /$opt_regex/ && !$opt_v ) {
                return 0;
            }
        }
        # ack always selects files that are specified on the command
        # line, regardless of filetype.  If you want to ack a JPEG,
        # and say "ack foo whatever.jpg" it will do it for you.
        return 1 if $is_member_of_starting_set{ get_file_id($File::Next::name) };

        if ( $dont_ignore_dir_filter ) {
            if ( $previous_dir eq $File::Next::dir ) {
                if ( $previous_dir_ignore_result ) {
                    return 0;
                }
            }
            else {
                my @dirs = File::Spec->splitdir($File::Next::dir);

                my $is_ignoring = 0;

                for ( my $i = 0; $i < @dirs; $i++) {
                    my $dir_rsrc = App::Ack::File->new(File::Spec->catfile(@dirs[0 .. $i]));

                    my $j = 0;
                    for my $filter (@ignore_dir_filter) {
                        if ( $filter->filter($dir_rsrc) ) {
                            $is_ignoring = !$is_inverted[$j];
                        }
                        $j++;
                    }
                }

                $previous_dir               = $File::Next::dir;
                $previous_dir_ignore_result = $is_ignoring;

                if ( $is_ignoring ) {
                    return 0;
                }
            }
        }

        # Ignore named pipes found in directory searching.  Named
        # pipes created by subprocesses get specified on the command
        # line, so the rule of "always select whatever is on the
        # command line" wins.
        return 0 if -p $File::Next::name;

        # We can't handle unreadable filenames; report them.
        if ( not -r _ ) {
            use filetest 'access';

            if ( not -R $File::Next::name ) {
                if ( $App::Ack::report_bad_filenames ) {
                    App::Ack::warn( "${File::Next::name}: cannot open file for reading" );
                }
                return 0;
            }
        }

        my $file = App::Ack::File->new($File::Next::name);

        if ( $ifiles_filters && $ifiles_filters->filter($file) ) {
            return 0;
        }

        my $match_found = $direct_filters->filter($file);

        # Don't bother invoking inverse filters unless we consider the current file a match.
        if ( $match_found && $inverse_filters->filter( $file ) ) {
            $match_found = 0;
        }
        return $match_found;
    };
}


# Returns a (fairly) unique identifier for a file.
# Use this function to compare two files to see if they're
# equal (ie. the same file, but with a different path/links/etc).
sub get_file_id {
    my ( $filename ) = @_;

    if ( $App::Ack::is_windows ) {
        return File::Next::reslash( $filename );
    }
    else {
        # XXX Is this the best method? It always hits the FS.
        if ( my ( $dev, $inode ) = (stat($filename))[0, 1] ) {
            return join(':', $dev, $inode);
        }
        else {
            # XXX This could be better.
            return $filename;
        }
    }
}

# Returns a regex object based on a string and command-line options.
# Dies when the regex $str is undefined (i.e. not given on command line).

sub build_regex {
    my $str = shift;
    my $opt = shift;

    defined $str or App::Ack::die( 'No regular expression found.' );

    # Check for lowercaseness before we do any modifications.
    my $regex_is_lc = $str eq lc $str;

    $str = quotemeta( $str ) if $opt->{Q};

    # Whole words only.
    if ( $opt->{w} ) {
        my $ok = 1;

        if ( $str =~ /^\\[wd]/ ) {
            # Explicit \w is good.
        }
        else {
            # Can start with \w, (, [ or dot.
            if ( $str !~ /^[\w\(\[\.]/ ) {
                $ok = 0;
            }
        }

        # Can end with \w, }, ), ], +, *, or dot.
        if ( $str !~ /[\w\}\)\]\+\*\?\.]$/ ) {
            $ok = 0;
        }
        # ... unless it's escaped.
        elsif ( $str =~ /\\[\}\)\]\+\*\?\.]$/ ) {
            $ok = 0;
        }

        if ( !$ok ) {
            App::Ack::die( '-w will not do the right thing if your regex does not begin and end with a word character.' );
        }

        if ( $str =~ /^\w+$/ ) {
            # No need for fancy regex if it's a simple word.
            $str = sprintf( '\b(?:%s)\b', $str );
        }
        else {
            $str = sprintf( '(?:^|\b|\s)\K(?:%s)(?=\s|\b|$)', $str );
        }
    }

    if ( $opt->{i} || ($opt->{smart_case} && $regex_is_lc) ) {
        $str = "(?i)$str";
    }

    my $re = eval { qr/$str/m };
    if ( !$re ) {
        my $err = $@;
        chomp $err;
        App::Ack::die( "Invalid regex '$str':\n  $err" );
    }

    return $re;

}

my $match_colno;

{

# Number of context lines
my $n_before_ctx_lines;
my $n_after_ctx_lines;

# Array to keep track of lines that might be required for a "before" context
my @before_context_buf;
# Position to insert next line in @before_context_buf
my $before_context_pos;

# Number of "after" context lines still pending
my $after_context_pending;

# Number of latest line that got printed
my $printed_lineno;

my $is_iterating;

my $is_first_match;
state $has_printed_something = 0;

# Set up context tracking variables.
sub set_up_line_context {
    $n_before_ctx_lines = $opt_output ? 0 : ($opt_before_context || 0);
    $n_after_ctx_lines  = $opt_output ? 0 : ($opt_after_context || 0);

    @before_context_buf = (undef) x $n_before_ctx_lines;
    $before_context_pos = 0;

    $is_tracking_context = $n_before_ctx_lines || $n_after_ctx_lines;

    $is_first_match = 1;

    return;
}

# Adjust context tracking variables when entering a new file.
sub set_up_line_context_for_file {
    $printed_lineno = 0;
    $after_context_pending = 0;
    if ( $opt_heading && !$opt_lines ) {
        $is_first_match = 1;
    }

    return;
}

=begin Developers

This subroutine jumps through a number of optimization hoops to
try to be fast in the more common use cases of ack.  For one thing,
in non-context tracking searches (not using -A, -B, or -C),
conditions that normally would be checked inside the loop happen
outside, resulting in three nearly identical loops for -v, --passthru,
and normal searching.  Any changes that happen to one should propagate
to the others if they make sense.  The non-context branches also inline
does_match for performance reasons; any relevant changes that happen here
must also happen there.

=end Developers

=cut

sub print_matches_in_file {
    my ( $file ) = @_;

    my $max_count = $opt_m || -1;   # Go negative for no limit so it can never reduce to 0.
    my $nmatches  = 0;
    my $filename  = $file->name;
    my $ors       = $opt_print0 ? "\0" : "\n";

    my $has_printed_for_this_file = 0;

    $is_iterating = 1;

    my $fh = $file->open;
    if ( !$fh ) {
        if ( $App::Ack::report_bad_filenames ) {
            App::Ack::warn( "$filename: $!" );
        }
        return 0;
    }

    my $display_filename = $filename;
    if ( $opt_show_filename && $opt_heading && $opt_color ) {
        $display_filename = Term::ANSIColor::colored($display_filename, $ENV{ACK_COLOR_FILENAME});
    }

    # Check for context before the main loop, so we don't pay for it if we don't need it.
    if ( $is_tracking_context ) {
        $after_context_pending = 0;
        while ( <$fh> ) {
            if ( does_match( $_ ) && $max_count ) {
                if ( !$has_printed_for_this_file ) {
                    if ( $opt_break && $has_printed_something ) {
                        App::Ack::print_blank_line();
                    }
                    if ( $opt_show_filename && $opt_heading ) {
                        App::Ack::print_filename( $display_filename, $ors );
                    }
                }
                print_line_with_context( $filename, $_, $. );
                $has_printed_for_this_file = 1;
                $nmatches++;
                $max_count--;
            }
            elsif ( $opt_passthru ) {
                chomp; # XXX Proper newline handling?
                # XXX Inline this call?
                if ( $opt_break && !$has_printed_for_this_file && $has_printed_something ) {
                    App::Ack::print_blank_line();
                }
                print_line_with_options( $filename, $_, $., ':' );
                $has_printed_for_this_file = 1;
            }
            else {
                chomp; # XXX Proper newline handling?
                print_line_if_context( $filename, $_, $., '-' );
            }

            last if ($max_count == 0) && ($after_context_pending == 0);
        }
    }
    else {  # Not tracking context
        if ( $opt_passthru ) {
            local $_ = undef;

            while ( <$fh> ) {
                $match_colno = undef;
                if ( $opt_v ? !/$opt_regex/o : /$opt_regex/o ) {
                    if ( !$opt_v ) {
                        $match_colno = $-[0] + 1;
                    }
                    if ( !$has_printed_for_this_file ) {
                        if ( $opt_break && $has_printed_something ) {
                            App::Ack::print_blank_line();
                        }
                        if ( $opt_show_filename && $opt_heading ) {
                            App::Ack::print_filename( $display_filename, $ors );
                        }
                    }
                    print_line_with_context( $filename, $_, $. );
                    $has_printed_for_this_file = 1;
                    $nmatches++;
                    $max_count--;
                }
                else {
                    chomp; # XXX proper newline handling?
                    if ( $opt_break && !$has_printed_for_this_file && $has_printed_something ) {
                        App::Ack::print_blank_line();
                    }
                    print_line_with_options( $filename, $_, $., ':' );
                    $has_printed_for_this_file = 1;
                }
                last if $max_count == 0;
            }
        }
        elsif ( $opt_v ) {
            local $_ = undef;

            $match_colno = undef;
            while ( <$fh> ) {
                if ( !/$opt_regex/o ) {
                    if ( !$has_printed_for_this_file ) {
                        if ( $opt_break && $has_printed_something ) {
                            App::Ack::print_blank_line();
                        }
                        if ( $opt_show_filename && $opt_heading ) {
                            App::Ack::print_filename( $display_filename, $ors );
                        }
                    }
                    print_line_with_context( $filename, $_, $. );
                    $has_printed_for_this_file = 1;
                    $nmatches++;
                    $max_count--;
                }
                last if $max_count == 0;
            }
        }
        else {
            local $_ = undef;

            my $last_match_lineno;
            while ( <$fh> ) {
                $match_colno = undef;
                if ( /$opt_regex/o ) {
                    $match_colno = $-[0] + 1;
                    if ( !$has_printed_for_this_file ) {
                        if ( $opt_break && $has_printed_something ) {
                            App::Ack::print_blank_line();
                        }
                        if ( $opt_show_filename && $opt_heading ) {
                            App::Ack::print_filename( $display_filename, $ors );
                        }
                    }
                    if ( $opt_proximate ) {
                        if ( $last_match_lineno ) {
                            if ( $. > $last_match_lineno + $opt_proximate ) {
                                App::Ack::print_blank_line();
                            }
                        }
                        elsif ( !$opt_break && $has_printed_something ) {
                            App::Ack::print_blank_line();
                        }
                    }
                    s/[\r\n]+$//g;
                    print_line_with_options( $filename, $_, $., ':' );
                    $has_printed_for_this_file = 1;
                    $nmatches++;
                    $max_count--;
                    $last_match_lineno = $.;
                }
                last if $max_count == 0;
            }
        }

    }

    $is_iterating = 0;

    return $nmatches;
}


sub print_line_with_options {
    my ( $filename, $line, $lineno, $separator ) = @_;

    $has_printed_something = 1;
    $printed_lineno = $lineno;

    my $ors = $opt_print0 ? "\0" : "\n";

    my @line_parts;

    # Figure out how many spaces are used per line for the ANSI coloring.
    state $chars_used_by_coloring;
    if ( !defined($chars_used_by_coloring) ) {
        $chars_used_by_coloring = 0;
        if ( $opt_color ) {
            my $filename_uses = length( Term::ANSIColor::colored( 'x', $ENV{ACK_COLOR_FILENAME} ) ) - 1;
            my $lineno_uses   = length( Term::ANSIColor::colored( 'x', $ENV{ACK_COLOR_LINENO} ) ) - 1;
            if ( $opt_heading ) {
                $chars_used_by_coloring = $lineno_uses;
            }
            else {
                $chars_used_by_coloring = $filename_uses + $lineno_uses;
            }
        }
    }

    if ( $opt_show_filename ) {
        if ( $opt_color ) {
            $filename = Term::ANSIColor::colored( $filename, $ENV{ACK_COLOR_FILENAME} );
            $lineno   = Term::ANSIColor::colored( $lineno,   $ENV{ACK_COLOR_LINENO} );
        }
        if ( $opt_heading ) {
            push @line_parts, $lineno;
        }
        else {
            push @line_parts, $filename, $lineno;
        }

        if ( $opt_column ) {
            push @line_parts, get_match_colno();
        }
    }

    if ( $opt_output ) {
        while ( $line =~ /$opt_regex/og ) {
            my $output = eval $opt_output;
            App::Ack::print( join( $separator, @line_parts, $output ), $ors );
        }
    }
    else {
        my $underline = '';

        # We have to do underlining before any highlighting because highlighting modifies string length.
        if ( $opt_u ) {
            while ( $line =~ /$opt_regex/og ) {
                my $match_start = $-[0];
                next unless defined($match_start);

                my $match_end = $+[0];
                my $match_length = $match_end - $match_start;
                last if $match_length <= 0;

                my $spaces_needed = $match_start - length $underline;

                $underline .= (' ' x $spaces_needed);
                $underline .= ('^' x $match_length);
            }
        }
        if ( $opt_color ) {
            my $highlighted = 0; # If highlighted, need to escape afterwards.

            while ( $line =~ /$opt_regex/og ) {
                my $match_start = $-[0];
                next unless defined($match_start);

                my $match_end = $+[0];
                my $match_length = $match_end - $match_start;
                last if $match_length <= 0;

                if ( $opt_color ) {
                    my $substring    = substr( $line, $match_start, $match_length );
                    my $substitution = Term::ANSIColor::colored( $substring, $ENV{ACK_COLOR_MATCH} );

                    # Fourth argument replaces the string specified by the first three.
                    substr( $line, $match_start, $match_length, $substitution );

                    # Move the offset of where /g left off forward the number of spaces of highlighting.
                    pos($line) = $match_end + (length( $substitution ) - length( $substring ));
                    $highlighted = 1;
                }
            }
            # Reset formatting and delete everything to the end of the line.
            $line .= "\033[0m\033[K" if $highlighted;   ## no critic ( ValuesAndExpressions::ProhibitEscapedCharacters )
        }

        push @line_parts, $line;
        App::Ack::print( join( $separator, @line_parts ), $ors );

        if ( $underline ne '' ) {
            pop @line_parts; # Leave only the stuff on the left.
            if ( @line_parts ) {
                my $stuff_on_the_left = join( $separator, @line_parts );
                my $spaces_needed = length($stuff_on_the_left) - $chars_used_by_coloring + 1;

                App::Ack::print( ' ' x $spaces_needed );
            }
            App::Ack::print( $underline, $ors );
        }
    }

    return;
}

sub iterate {
    my ( $file, $cb ) = @_;

    $is_iterating = 1;

    my $fh = $file->open;
    if ( !$fh ) {
        if ( $App::Ack::report_bad_filenames ) {
            App::Ack::warn( $file->name . ': ' . $! );
        }
        return;
    }

    # Check for context before the main loop, so we don't pay for it if we don't need it.
    if ( $is_tracking_context ) {
        $after_context_pending = 0;

        while ( <$fh> ) {
            last unless $cb->();
        }
    }
    else {
        local $_ = undef;

        while ( <$fh> ) {
            last unless $cb->();
        }
    }

    $is_iterating = 0;

    return;
}

sub print_line_with_context {
    my ( $filename, $matching_line, $lineno ) = @_;

    my $ors                 = $opt_print0 ? "\0" : "\n";
    my $is_tracking_context = $opt_after_context || $opt_before_context;

    $matching_line =~ s/[\r\n]+$//g;

    # Check if we need to print context lines first.
    if ( $is_tracking_context ) {
        my $before_unprinted = $lineno - $printed_lineno - 1;
        if ( !$is_first_match && ( !$printed_lineno || $before_unprinted > $n_before_ctx_lines ) ) {
            App::Ack::print('--', $ors);
        }

        # We want at most $n_before_ctx_lines of context.
        if ( $before_unprinted > $n_before_ctx_lines ) {
            $before_unprinted = $n_before_ctx_lines;
        }

        while ( $before_unprinted > 0 ) {
            my $line = $before_context_buf[($before_context_pos - $before_unprinted + $n_before_ctx_lines) % $n_before_ctx_lines];

            chomp $line;

            # Disable $opt->{column} since there are no matches in the context lines.
            local $opt_column = 0;

            print_line_with_options( $filename, $line, $lineno-$before_unprinted, '-' );
            $before_unprinted--;
        }
    }

    print_line_with_options( $filename, $matching_line, $lineno, ':' );

    # We want to get the next $n_after_ctx_lines printed.
    $after_context_pending = $n_after_ctx_lines;

    $is_first_match = 0;

    return;
}

# Print the line only if it's part of a context we need to display.
sub print_line_if_context {
    my ( $filename, $line, $lineno, $separator ) = @_;

    if ( $after_context_pending ) {
        # Disable $opt_column since there are no matches in the context lines.
        local $opt_column = 0;
        print_line_with_options( $filename, $line, $lineno, $separator );
        --$after_context_pending;
    }
    elsif ( $n_before_ctx_lines ) {
        # Save line for "before" context.
        $before_context_buf[$before_context_pos] = $_;
        $before_context_pos = ($before_context_pos+1) % $n_before_ctx_lines;
    }

    return;
}

}

# does_match() MUST have an $opt_regex set.

=begin Developers

This subroutine is inlined a few places in C<print_matches_in_file>
for performance reasons, so any changes here must be copied there as
well.

=end Developers

=cut

sub does_match {
    my ( $line ) = @_;

    $match_colno = undef;

    if ( $opt_v ) {
        return ( $line !~ /$opt_regex/o );
    }
    else {
        if ( $line =~ /$opt_regex/o ) {
            # @- = @LAST_MATCH_START
            # @+ = @LAST_MATCH_END
            $match_colno = $-[0] + 1;
            return 1;
        }
        else {
            return;
        }
    }
}

sub get_match_colno {
    return $match_colno;
}

sub file_has_match {
    my ( $file ) = @_;

    my $has_match = 0;
    my $fh = $file->open();
    if ( !$fh ) {
        if ( $App::Ack::report_bad_filenames ) {
            App::Ack::warn( $file->name . ': ' . $! );
        }
    }
    else {
        while ( <$fh> ) {
            if (/$opt_regex/o xor $opt_v) {
                $has_match = 1;
                last;
            }
        }
        close $fh;
    }

    return $has_match;
}

sub count_matches_in_file {
    my ( $file ) = @_;

    my $nmatches = 0;
    my $fh = $file->open;
    if ( !$fh ) {
        if ( $App::Ack::report_bad_filenames ) {
            App::Ack::warn( $file->name . ': ' . $! );
        }
    }
    else {
        while ( <$fh> ) {
            ++$nmatches if (/$opt_regex/o xor $opt_v);
        }
        close $fh;
    }

    return $nmatches;
}
