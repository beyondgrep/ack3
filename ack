#!/usr/bin/perl

use strict;
use warnings;

our $VERSION = 'v3.7.0'; # Check https://beyondgrep.com/ for updates

use 5.010001;

use File::Spec ();
use File::Next ();
use Getopt::Long ();

use App::Ack ();
use App::Ack::ConfigLoader ();
use App::Ack::File ();
use App::Ack::Files ();

use App::Ack::Filter ();
use App::Ack::Filter::Default ();
use App::Ack::Filter::Extension ();
use App::Ack::Filter::FirstLineMatch ();
use App::Ack::Filter::Inverse ();
use App::Ack::Filter::Is ();
use App::Ack::Filter::IsPath ();
use App::Ack::Filter::Match ();
use App::Ack::Filter::Collection ();

# Global command-line options
our $opt_1;
our $opt_A;
our $opt_B;
our $opt_break;
our $opt_color;
our $opt_column;
our $opt_debug;
our $opt_c;
our $opt_f;
our $opt_g;
our $opt_heading;
our $opt_L;
our $opt_l;
our $opt_m;
our $opt_output;
our $opt_passthru;
our $opt_p;
our $opt_range_start;
our $opt_range_end;
our $opt_range_invert;
our $opt_regex;
our $opt_show_filename;
our $opt_show_types;
our $opt_underline;
our $opt_v;

# Flag if we need any context tracking.
our $is_tracking_context;

# The regex that we search for in each file.
our $search_re;

# The regex that matches for things we want to exclude via the --not option.
our $search_not_re;

# Special /m version of our $search_re.
our $scan_re;

our @special_vars_used_by_opt_output;

our $using_ranges;

# Internal stats for debugging.
our %stats;

MAIN: {
    $App::Ack::ORIGINAL_PROGRAM_NAME = $0;
    $0 = join(' ', 'ack', $0);
    $App::Ack::ors = "\n";
    if ( $App::Ack::VERSION ne $main::VERSION ) {
        App::Ack::die( "Program/library version mismatch\n\t$0 is $main::VERSION\n\t$INC{'App/Ack.pm'} is $App::Ack::VERSION" );
    }

    # Do preliminary arg checking;
    my $env_is_usable = 1;
    for my $arg ( @ARGV ) {
        last if ( $arg eq '--' );

        # Get the --thpppt, --bar, --cathy and --man checking out of the way.
        $arg =~ /^--th[pt]+t+$/ and App::Ack::thpppt($arg);
        $arg eq '--bar'         and App::Ack::ackbar();
        $arg eq '--cathy'       and App::Ack::cathy();

        # See if we want to ignore the environment. (Don't tell Al Gore.)
        $arg eq '--env'         and $env_is_usable = 1;
        $arg eq '--noenv'       and $env_is_usable = 0;
    }

    if ( $env_is_usable ) {
        if ( $ENV{ACK_OPTIONS} ) {
            App::Ack::warn( 'WARNING: ack no longer uses the ACK_OPTIONS environment variable.  Use an ackrc file instead.' );
        }
    }
    else {
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
        $ENV{ACK_COLOR_COLNO}    ||= 'bold yellow';
    }

    App::Ack::ConfigLoader::configure_parser( 'no_auto_abbrev', 'pass_through' );
    Getopt::Long::GetOptions(
        help     => sub { App::Ack::show_help(); exit; },
        version  => sub { App::Ack::print( App::Ack::get_version_statement() ); exit; },
        man      => sub { App::Ack::show_man(); },
    );

    if ( !@ARGV ) {
        App::Ack::show_help();
        exit 1;
    }

    my @arg_sources = App::Ack::ConfigLoader::retrieve_arg_sources();

    my $opt = App::Ack::ConfigLoader::process_args( @arg_sources );

    $opt_1              = $opt->{1};
    $opt_A              = $opt->{A};
    $opt_B              = $opt->{B};
    $opt_break          = $opt->{break};
    $opt_c              = $opt->{c};
    $opt_color          = $opt->{color};
    $opt_column         = $opt->{column};
    $opt_debug          = $opt->{debug};
    $opt_f              = $opt->{f};
    $opt_g              = $opt->{g};
    $opt_heading        = $opt->{heading};
    $opt_L              = $opt->{L};
    $opt_l              = $opt->{l};
    $opt_m              = $opt->{m};
    $opt_output         = $opt->{output};
    $opt_p              = $opt->{p};
    $opt_passthru       = $opt->{passthru};
    $opt_range_start    = $opt->{range_start};
    $opt_range_end      = $opt->{range_end};
    $opt_range_invert   = $opt->{range_invert};
    $opt_regex          = $opt->{regex};
    $opt_show_filename  = $opt->{show_filename};
    $opt_show_types     = $opt->{show_types};
    $opt_underline      = $opt->{underline};
    $opt_v              = $opt->{v};

    if ( $opt_show_types && not( $opt_f || $opt_g ) ) {
        App::Ack::die( '--show-types can only be used with -f or -g.' );
    }

    if ( $opt_range_start ) {
        ($opt_range_start, undef) = build_regex( $opt_range_start, {} );
    }
    if ( $opt_range_end ) {
        ($opt_range_end, undef)   = build_regex( $opt_range_end, {} );
    }
    $using_ranges = $opt_range_start || $opt_range_end;

    $App::Ack::report_bad_filenames = !$opt->{s};
    $App::Ack::ors = $opt->{print0} ? "\0" : "\n";

    if ( !defined($opt_color) && !$opt_g ) {
        my $windows_color = 1;
        if ( $App::Ack::is_windows ) {
            $windows_color = eval { require Win32::Console::ANSI; };
        }
        $opt_color = !App::Ack::output_to_pipe() && $windows_color;
    }
    $opt_heading //= !App::Ack::output_to_pipe();
    $opt_break //= !App::Ack::output_to_pipe();

    if ( defined($opt->{H}) || defined($opt->{h}) ) {
        $opt_show_filename = $opt->{show_filename} = $opt->{H} && !$opt->{h};
    }

    if ( defined $opt_output ) {
        # Expand out \t, \n and \r.
        $opt_output =~ s/\\n/\n/g;
        $opt_output =~ s/\\r/\r/g;
        $opt_output =~ s/\\t/\t/g;

        my @supported_special_variables = ( 1..9, qw( _ . ` & ' +  f ) );
        @special_vars_used_by_opt_output = grep { $opt_output =~ /\$$_/ } @supported_special_variables;

        # If the $opt_output contains $&, $` or $', those vars won't be
        # captured until they're used at least once in the program.
        # Do the eval to make this happen.
        for my $i ( @special_vars_used_by_opt_output ) {
            if ( $i eq q{&} || $i eq q{'} || $i eq q{`} ) {
                no warnings;    # They will be undef, so don't warn.
                eval qq{"\$$i"};    ## no critic ( ErrorHandling::RequireCheckingReturnValueOfEval )
            }
        }
    }

    # Set up file filters.
    my $files;
    if ( $App::Ack::is_filter_mode && !$opt->{files_from} ) { # probably -x
        $files     = App::Ack::Files->from_stdin();
        $opt_regex //= shift @ARGV;
        ($search_re, $scan_re) = build_regex( $opt_regex, $opt );
        $search_not_re = _build_search_not_re( $opt );
        $stats{search_re} = $search_re;
        $stats{scan_re} = $scan_re;
        $stats{search_not_re} = $search_not_re;
    }
    else {
        if ( $opt_f ) {
            # No need to check for regex, since mutex options are handled elsewhere.
        }
        else {
            $opt_regex //= shift @ARGV;
            ($search_re, $scan_re) = build_regex( $opt_regex, $opt );
            $search_not_re = _build_search_not_re( $opt );
            $stats{search_re} = $search_re;
            $stats{scan_re} = $scan_re;
            $stats{search_not_re} = $search_not_re;
        }
        # XXX What is this checking for?
        if ( $search_re && $search_re =~ /\n/ ) {
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

    my $nmatches;
    if ( $opt_f || $opt_g ) {
        $nmatches = file_loop_fg( $files );
    }
    elsif ( $opt_c ) {
        $nmatches = file_loop_c( $files );
    }
    elsif ( $opt_l || $opt_L ) {
        $nmatches = file_loop_lL( $files );
    }
    else {
        $nmatches = file_loop_normal( $files );
    }

    if ( $opt_debug ) {
        require List::Util;
        my @stats = qw( search_re scan_re search_not_re prescans linescans filematches linematches );
        my $width = List::Util::max( map { length } @stats );

        for my $stat ( @stats ) {
            App::Ack::warn( sprintf( '%-*.*s = %s', $width, $width, $stat, $stats{$stat} // 'undef' ) );
        }
    }

    close $App::Ack::fh;

    App::Ack::exit_from_ack( $nmatches );
}

# End of MAIN

sub file_loop_fg {
    my $files = shift;

    my $nmatches = 0;
    while ( defined( my $file = $files->next ) ) {
        if ( $opt_show_types ) {
            App::Ack::show_types( $file );
        }
        elsif ( $opt_g ) {
            print_line_with_options( undef, $file->name, 0, $App::Ack::ors );
        }
        else {
            App::Ack::say( $file->name );
        }
        ++$nmatches;
        last if defined($opt_m) && ($nmatches >= $opt_m);
    }

    return $nmatches;
}


sub file_loop_c {
    my $files = shift;

    my $total_count = 0;
    while ( defined( my $file = $files->next ) ) {
        my $matches_for_this_file = count_matches_in_file( $file );

        if ( not $opt_show_filename ) {
            $total_count += $matches_for_this_file;
            next;
        }

        if ( !$opt_l || $matches_for_this_file > 0 ) {
            if ( $opt_show_filename ) {
                my $display_filename = $file->name;
                if ( $opt_color ) {
                    $display_filename = Term::ANSIColor::colored($display_filename, $ENV{ACK_COLOR_FILENAME});
                }
                App::Ack::say( $display_filename, ':', $matches_for_this_file );
            }
            else {
                App::Ack::say( $matches_for_this_file );
            }
        }
    }

    if ( !$opt_show_filename ) {
        App::Ack::say( $total_count );
    }

    return;
}


sub file_loop_lL {
    my $files = shift;

    my $nmatches = 0;
    while ( defined( my $file = $files->next ) ) {
        my $is_match = count_matches_in_file( $file, 1 );

        if ( $opt_L ? !$is_match : $is_match ) {
            App::Ack::say( $file->name );
            ++$nmatches;

            last if $opt_1;
            last if defined($opt_m) && ($nmatches >= $opt_m);
        }
    }

    return $nmatches;
}


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
            if ( $File::Next::name =~ /$search_re/o ) {
                return 0 if $opt_v;
            }
            else {
                return 0 if !$opt_v;
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

    if ( !$opt->{Q} ) {
        # Compile the regex to see if it dies or throws warnings.
        local $SIG{__WARN__} = sub { die @_ };  # Anything that warns becomes a die.
        my $scratch_regex = eval { qr/$str/ };
        if ( not $scratch_regex ) {
            my $err = $@;
            chomp $err;

            if ( $err =~ m{^(.+?); marked by <-- HERE in m/(.+?) <-- HERE} ) {
                my ($why, $where) = ($1,$2);
                my $pointy = ' ' x (6+length($where)) . '^---HERE';
                App::Ack::die( "Invalid regex '$str'\nRegex: $str\n$pointy $why" );
            }
            else {
                App::Ack::die( "Invalid regex '$str'\n$err" );
            }
        }
    }

    # Check for lowercaseness before we do any modifications.
    my $regex_is_lc = App::Ack::is_lowercase( $str );

    $str = quotemeta( $str ) if $opt->{Q};

    my $scan_str = $str;

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

    if ( $opt->{i} || ($opt->{S} && $regex_is_lc) ) {
        $_ = "(?i)$_" for ( $str, $scan_str );
    }

    my $scan_regex = undef;
    my $regex = eval { qr/$str/ };
    if ( $regex ) {
        if ( $scan_str !~ /\$/ ) {
            # No line_scan is possible if there's a $ in the regex.
            $scan_regex = eval { qr/$scan_str/m };
        }
    }
    else {
        my $err = $@;
        chomp $err;
        App::Ack::die( "Invalid regex '$str':\n  $err" );
    }

    return ($regex, $scan_regex);
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

my $is_first_match;
state $has_printed_from_any_file = 0;


sub file_loop_normal {
    my $files = shift;

    $n_before_ctx_lines = $opt_output ? 0 : ($opt_B || 0);
    $n_after_ctx_lines  = $opt_output ? 0 : ($opt_A || 0);

    @before_context_buf = (undef) x $n_before_ctx_lines;
    $before_context_pos = 0;

    $is_tracking_context = $n_before_ctx_lines || $n_after_ctx_lines;

    $is_first_match = 1;

    my $nmatches = 0;
    while ( defined( my $file = $files->next ) ) {
        if ($is_tracking_context) {
            $printed_lineno = 0;
            $after_context_pending = 0;
            if ( $opt_heading ) {
                $is_first_match = 1;
            }
        }
        my $needs_line_scan = 1;
        if ( !$opt_passthru && !$opt_v ) {
            $stats{prescans}++;
            if ( $file->may_be_present( $scan_re ) ) {
                $file->reset();
            }
            else {
                $needs_line_scan = 0;
            }
        }
        if ( $needs_line_scan ) {
            $stats{linescans}++;
            $nmatches += print_matches_in_file( $file );
        }
        last if $opt_1 && $nmatches;
    }

    return $nmatches;
}


sub print_matches_in_file {
    my $file = shift;

    my $max_count = $opt_m || -1;   # Go negative for no limit so it can never reduce to 0.
    my $nmatches  = 0;
    my $filename  = $file->name;

    my $has_printed_from_this_file = 0;

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
        local $_ = undef;

        $after_context_pending = 0;

        my $in_range = range_setup();

        while ( <$fh> ) {
            chomp;
            $match_colno = undef;

            $in_range = 1 if ( $using_ranges && !$in_range && $opt_range_start && /$opt_range_start/o );

            my $does_match;
            if ( $in_range ) {
                $does_match = /$search_re/o;
                if ( $does_match && $search_not_re ) {
                    local @-;
                    $does_match = !/$search_not_re/o;
                }
                if ( $opt_v ) {
                    $does_match = !$does_match;
                }
                else {
                    if ( $does_match ) {
                        # @- = @LAST_MATCH_START
                        $match_colno = $-[0] + 1;
                    }
                }
            }

            if ( $does_match && $max_count ) {
                if ( !$has_printed_from_this_file ) {
                    $stats{filematches}++;
                    if ( $opt_break && $has_printed_from_any_file ) {
                        App::Ack::print_blank_line();
                    }
                    if ( $opt_show_filename && $opt_heading ) {
                        App::Ack::say( $display_filename );
                    }
                }
                print_line_with_context( $filename, $_, $. );
                $has_printed_from_this_file = 1;
                $stats{linematches}++;
                $nmatches++;
                $max_count--;
            }
            else {
                if ( $after_context_pending ) {
                    # Disable $opt_column since there are no matches in the context lines.
                    local $opt_column = 0;
                    print_line_with_options( $filename, $_, $., '-' );
                    --$after_context_pending;
                }
                elsif ( $n_before_ctx_lines ) {
                    # Save line for "before" context.
                    $before_context_buf[$before_context_pos] = $_;
                    $before_context_pos = ($before_context_pos+1) % $n_before_ctx_lines;
                }
            }

            $in_range = 0 if ( $using_ranges && $in_range && $opt_range_end && /$opt_range_end/o );

            last if ($max_count == 0) && ($after_context_pending == 0);
        }
    }
    elsif ( $opt_passthru ) {
        local $_ = undef;

        my $in_range = range_setup();

        while ( <$fh> ) {
            chomp;

            $in_range = 1 if ( $using_ranges && !$in_range && $opt_range_start && /$opt_range_start/o );

            $match_colno = undef;
            my $does_match = /$search_re/o;
            if ( $does_match && $search_not_re ) {
                local @-;
                $does_match = !/$search_not_re/o;
            }
            if ( $in_range && ($opt_v xor $does_match) ) {
                if ( !$opt_v ) {
                    $match_colno = $-[0] + 1;
                }
                if ( !$has_printed_from_this_file ) {
                    if ( $opt_break && $has_printed_from_any_file ) {
                        App::Ack::print_blank_line();
                    }
                    if ( $opt_show_filename && $opt_heading ) {
                        App::Ack::say( $display_filename );
                    }
                }
                print_line_with_options( $filename, $_, $., ':' );
                $has_printed_from_this_file = 1;
                $nmatches++;
                $max_count--;
            }
            else {
                if ( $opt_break && !$has_printed_from_this_file && $has_printed_from_any_file ) {
                    App::Ack::print_blank_line();
                }
                print_line_with_options( $filename, $_, $., '-', 1 );
                $has_printed_from_this_file = 1;
            }

            $in_range = 0 if ( $using_ranges && $in_range && $opt_range_end && /$opt_range_end/o );

            last if $max_count == 0;
        }
    }
    elsif ( $opt_v ) {
        local $_ = undef;

        $match_colno = undef;
        my $in_range = range_setup();

        while ( <$fh> ) {
            chomp;

            $in_range = 1 if ( $using_ranges && !$in_range && $opt_range_start && /$opt_range_start/o );

            if ( $in_range ) {
                my $does_match = /$search_re/o;
                if ( $does_match && $search_not_re ) {
                    # local @-; No need to localize this because we don't use @-.
                    $does_match = !/$search_not_re/o;
                }
                if ( !$does_match ) {
                    if ( !$has_printed_from_this_file ) {
                        if ( $opt_break && $has_printed_from_any_file ) {
                            App::Ack::print_blank_line();
                        }
                        if ( $opt_show_filename && $opt_heading ) {
                            App::Ack::say( $display_filename );
                        }
                    }
                    print_line_with_context( $filename, $_, $. );
                    $has_printed_from_this_file = 1;
                    $nmatches++;
                    $max_count--;
                }
            }

            $in_range = 0 if ( $using_ranges && $in_range && $opt_range_end && /$opt_range_end/o );

            last if $max_count == 0;
        }
    }
    else {  # Normal search: No context, no -v, no --passthru
        local $_ = undef;

        my $last_match_lineno;
        my $in_range = range_setup();

        while ( <$fh> ) {
            chomp;

            $in_range = 1 if ( $using_ranges && !$in_range && $opt_range_start && /$opt_range_start/o );

            if ( $in_range ) {
                $match_colno = undef;
                my $is_match = /$search_re/o;
                if ( $is_match && $search_not_re ) {
                    local @-;
                    $is_match = !/$search_not_re/o;
                }
                if ( $is_match ) {
                    $match_colno = $-[0] + 1;
                    if ( !$has_printed_from_this_file ) {
                        $stats{filematches}++;
                        if ( $opt_break && $has_printed_from_any_file ) {
                            App::Ack::print_blank_line();
                        }
                        if ( $opt_show_filename && $opt_heading ) {
                            App::Ack::say( $display_filename );
                        }
                    }
                    if ( $opt_p ) {
                        if ( $last_match_lineno ) {
                            if ( $. > $last_match_lineno + $opt_p ) {
                                App::Ack::print_blank_line();
                            }
                        }
                        elsif ( !$opt_break && $has_printed_from_any_file ) {
                            App::Ack::print_blank_line();
                        }
                    }
                    s/[\r\n]+$//;
                    print_line_with_options( $filename, $_, $., ':' );
                    $has_printed_from_this_file = 1;
                    $nmatches++;
                    $stats{linematches}++;
                    $max_count--;
                    $last_match_lineno = $.;
                }
            }

            $in_range = 0 if ( $using_ranges && $in_range && $opt_range_end && /$opt_range_end/o );

            last if $max_count == 0;
        }
    }

    return $nmatches;
}


sub print_line_with_options {
    my ( $filename, $line, $lineno, $separator, $skip_coloring ) = @_;

    $has_printed_from_any_file = 1;
    $printed_lineno = $lineno;

    my @line_parts;

    if ( $opt_show_filename && defined($filename) ) {
        my $colno;
        $colno = get_match_colno() if $opt_column;
        if ( $opt_color ) {
            $filename = Term::ANSIColor::colored( $filename, $ENV{ACK_COLOR_FILENAME} );
            $lineno   = Term::ANSIColor::colored( $lineno,   $ENV{ACK_COLOR_LINENO} );
            $colno    = Term::ANSIColor::colored( $colno,    $ENV{ACK_COLOR_COLNO} ) if $opt_column;
        }
        if ( $opt_heading ) {
            push @line_parts, $lineno;
        }
        else {
            push @line_parts, $filename, $lineno;
        }
        push @line_parts, $colno if $opt_column;
    }

    if ( $opt_output ) {
        while ( $line =~ /$search_re/og ) {
            my $output = $opt_output;
            if ( @special_vars_used_by_opt_output ) {
                no strict;

                # Stash copies of the special variables because we can't rely
                # on them not changing in the process of doing the s///.

                my %keep = map { ($_ => ${$_} // '') } @special_vars_used_by_opt_output;
                $keep{_} = $line if exists $keep{_}; # Manually set it because $_ gets reset in a map.
                $keep{f} = $filename if exists $keep{f};
                my $special_vars_used_by_opt_output = join( '', @special_vars_used_by_opt_output );
                $output =~ s/\$([$special_vars_used_by_opt_output])/$keep{$1}/ego;
            }
            App::Ack::say( join( $separator, @line_parts, $output ) );
        }
    }
    else {
        my $underline = '';

        # We have to do underlining before any highlighting because highlighting modifies string length.
        if ( $opt_underline && !$skip_coloring ) {
            while ( $line =~ /$search_re/og ) {
                my $match_start = $-[0] // next;
                my $match_end = $+[0];
                my $match_length = $match_end - $match_start;
                last if $match_length <= 0;

                my $spaces_needed = $match_start - length $underline;

                $underline .= (' ' x $spaces_needed);
                $underline .= ('^' x $match_length);
            }
        }
        if ( $opt_color && !$skip_coloring ) {
            my $highlighted = 0; # If highlighted, need to escape afterwards.

            while ( $line =~ /$search_re/og ) {
                my $match_start = $-[0] // next;
                my $match_end = $+[0];
                my $match_length = $match_end - $match_start;
                last if $match_length <= 0;

                my $substring    = substr( $line, $match_start, $match_length );
                my $substitution = Term::ANSIColor::colored( $substring, $ENV{ACK_COLOR_MATCH} );

                # Fourth argument replaces the string specified by the first three.
                substr( $line, $match_start, $match_length, $substitution );

                # Move the offset of where /g left off forward the number of spaces of highlighting.
                pos($line) = $match_end + (length( $substitution ) - length( $substring ));
                $highlighted = 1;
            }
            # Reset formatting and delete everything to the end of the line.
            $line .= "\e[0m\e[K" if $highlighted;
        }

        push @line_parts, $line;
        App::Ack::say( join( $separator, @line_parts ) );

        # Print the underline, if appropriate.
        if ( $underline ne '' ) {
            # Figure out how many spaces are used per line for the ANSI coloring.
            state $chars_used_by_coloring;
            if ( !defined($chars_used_by_coloring) ) {
                $chars_used_by_coloring = 0;
                if ( $opt_color ) {
                    my $len_fn = sub { length( Term::ANSIColor::colored( 'x', $ENV{$_[0]} ) ) - 1 };
                    $chars_used_by_coloring += $len_fn->('ACK_COLOR_FILENAME') unless $opt_heading;
                    $chars_used_by_coloring += $len_fn->('ACK_COLOR_LINENO');
                    $chars_used_by_coloring += $len_fn->('ACK_COLOR_COLNO') if $opt_column;
                }
            }

            pop @line_parts; # Leave only the stuff on the left.
            if ( @line_parts ) {
                my $stuff_on_the_left = join( $separator, @line_parts );
                my $spaces_needed = length($stuff_on_the_left) - $chars_used_by_coloring + 1;

                App::Ack::print( ' ' x $spaces_needed );
            }
            App::Ack::say( $underline );
        }
    }

    return;
}

sub print_line_with_context {
    my ( $filename, $matching_line, $lineno ) = @_;

    $matching_line =~ s/[\r\n]+$//;

    # Check if we need to print context lines first.
    if ( $opt_A || $opt_B ) {
        my $before_unprinted = $lineno - $printed_lineno - 1;
        if ( !$is_first_match && ( !$printed_lineno || $before_unprinted > $n_before_ctx_lines ) ) {
            App::Ack::say( '--' );
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

}

sub get_match_colno {
    return $match_colno;
}

sub count_matches_in_file {
    my $file = shift;
    my $bail = shift;   # True if we're just checking for existence.

    my $nmatches = 0;
    my $do_scan = 1;

    if ( !$file->open() ) {
        $do_scan = 0;
        if ( $App::Ack::report_bad_filenames ) {
            App::Ack::warn( $file->name . ": $!" );
        }
    }
    else {
        if ( !$opt_v ) {
            if ( !$file->may_be_present( $scan_re ) ) {
                $do_scan = 0;
            }
        }
    }

    if ( $do_scan ) {
        $file->reset();

        my $in_range = range_setup();

        my $fh = $file->{fh};
        if ( $using_ranges ) {
            while ( <$fh> ) {
                chomp;
                $in_range = 1 if ( !$in_range && $opt_range_start && /$opt_range_start/o );
                if ( $in_range ) {
                    my $is_match = /$search_re/o;
                    if ( $is_match && $search_not_re ) {
                        $is_match = !/$search_not_re/o;
                    }
                    if ( $is_match xor $opt_v ) {
                        ++$nmatches;
                        last if $bail;
                    }
                }
                $in_range = 0 if ( $in_range && $opt_range_end && /$opt_range_end/o );
            }
        }
        else {
            while ( <$fh> ) {
                chomp;
                my $is_match = /$search_re/o;
                if ( $is_match && $search_not_re ) {
                    $is_match = !/$search_not_re/o;
                }
                if ( $is_match xor $opt_v ) {
                    ++$nmatches;
                    last if $bail;
                }
            }
        }
    }
    $file->close;

    return $nmatches;
}


sub range_setup {
    return !$using_ranges || (!$opt_range_start && $opt_range_end);
}


sub _build_search_not_re {
    my $opt = shift;

    my @not = @{$opt->{not}};

    if ( @not ) {
        my @built;
        for my $re ( @not ) {
            my ($built,undef) = build_regex( $re, $opt );
            push( @built, $built );
        }
        return join( '|', @built );
    }

    return;
}


=pod

=encoding UTF-8

=head1 NAME

ack - grep-like text finder

=head1 SYNOPSIS

    ack [options] PATTERN [FILE...]
    ack -f [options] [DIRECTORY...]

=head1 DESCRIPTION

ack is designed as an alternative to F<grep> for programmers.

ack searches the named input FILEs or DIRECTORYs for lines containing a
match to the given PATTERN.  By default, ack prints the matching lines.
If no FILE or DIRECTORY is given, the current directory will be searched.

PATTERN is a Perl regular expression.  Perl regular expressions
are commonly found in other programming languages, but for the particulars
of their behavior, please consult
L<perlreref|https://perldoc.perl.org/perlreref.html>.  If you don't know
how to use regular expression but are interested in learning, you may
consult L<perlretut|https://perldoc.perl.org/perlretut.html>.  If you do not
need or want ack to use regular expressions, please see the
C<-Q>/C<--literal> option.

Ack can also list files that would be searched, without actually
searching them, to let you take advantage of ack's file-type filtering
capabilities.

=head1 FILE SELECTION

If files are not specified for searching, either on the command
line or piped in with the C<-x> option, I<ack> delves into
subdirectories selecting files for searching.

I<ack> is intelligent about the files it searches.  It knows about
certain file types, based on both the extension on the file and,
in some cases, the contents of the file.  These selections can be
made with the B<--type> option.

With no file selection, I<ack> searches through regular files that
are not explicitly excluded by B<--ignore-dir> and B<--ignore-file>
options, either present in F<ackrc> files or on the command line.

The default options for I<ack> ignore certain files and directories.  These
include:

=over 4

=item * Backup files: Files matching F<#*#> or ending with F<~>.

=item * Coredumps: Files matching F<core.\d+>

=item * Version control directories like F<.svn> and F<.git>.

=back

Run I<ack> with the C<--dump> option to see what settings are set.

However, I<ack> always searches the files given on the command line,
no matter what type.  If you tell I<ack> to search in a coredump,
it will search in a coredump.

=head1 DIRECTORY SELECTION

I<ack> descends through the directory tree of the starting directories
specified.  If no directories are specified, the current working directory is
used.  However, it will ignore the shadow directories used by
many version control systems, and the build directories used by the
Perl MakeMaker system.  You may add or remove a directory from this
list with the B<--[no]ignore-dir> option. The option may be repeated
to add/remove multiple directories from the ignore list.

For a complete list of directories that do not get searched, run
C<ack --dump>.

=head1 MATCHING IN A RANGE OF LINES

The C<--range-start> and C<--range-end> options let you specify ranges of
lines to search within each file.

Say you had the following file, called F<testfile>:

    # This function calls print on "foo".
    sub foo {
        print 'foo';
    }
    my $print = 1;
    sub bar {
        print 'bar';
    }
    my $task = 'print';

Calling C<ack print> will give us five matches:

    $ ack print testfile
    # This function calls print on "foo".
        print 'foo';
    my $print = 1;
        print 'bar';
    my $task = 'print';

What if we only want to search for C<print> within the subroutines?  We can
specify ranges of lines that we want ack to search.  The range starts with
any line that matches the pattern C<^sub \w+>, and stops with any line that
matches C<^}>.

    $ ack --range-start='^sub \w+' --range-end='^}' print testfile
        print 'foo';
        print 'bar';

Note that ack searched two ranges of lines.  The listing below shows which
lines were in a range and which were out of the range.

    Out # This function calls print on "foo".
    In  sub foo {
    In      print 'foo';
    In  }
    Out my $print = 1;
    In  sub bar {
    In      print 'bar';
    In  }
    Out my $task = 'print';

You don't have to specify both C<--range-start> and C<--range-end>.  IF
C<--range-start> is omitted, then the range runs from the first line in the
file until the first line that matches C<--range-end>.  Similarly, if
C<--range-end> is omitted, the range runs from the first line matching
C<--range-start> to the end of the file.

For example, if you wanted to search all HTML files up until the first
instance of the C<< <body> >>, you could do

    ack foo --html --range-end='<body>'

Or to search after Perl's `__DATA__` or `__END__` markers, you would do

    ack pattern --perl --range-start='^__(END|DATA)__'

It's possible for a range to start and stop on the same line.  For example

    --range-start='<title>' --range-end='</title>'

would match this line as both the start and end of the range, making a
one-line range.

    <title>Page title</title>

Note that the patterns in C<--range-start> and C<--range-end> are not
affected by options like C<-i>, C<-w> and C<-Q> that modify the behavior of
the main pattern being matched.

Again, ranges only affect where matches are looked for.  Everything else in
ack works the same way.  Using C<-c> option with a range will give a count
of all the matches that appear within those ranges.  The C<-l> shows those
files that have a match within a range, and the C<-L> option shows files
that do not have a match within a range.

The C<-v> option for negating a match works inside the range, too.
To see lines that don't match "google" within the "<head>" section of
your HTML files, you could do:

    ack google -v --html --range-start='<head' --range-end='</head>'

Specifying a range to search does not affect how matches are displayed.
The context for a match will still be the same, and

Using the context options work the same way, and will show context
lines for matches even if the context lines fall outside the range.
Similarly, C<--passthru> will show all lines in the file, but only show
matches for lines within the range.

=head1 OPTIONS

=over 4

=item B<--ackrc>

Specifies an ackrc file to load after all others; see L</"ACKRC LOCATION SEMANTICS">.

=item B<-A I<NUM>>, B<--after-context=I<NUM>>

Print I<NUM> lines of trailing context after matching lines.

=item B<-B I<NUM>>, B<--before-context=I<NUM>>

Print I<NUM> lines of leading context before matching lines.

=item B<--[no]break>

Print a break between results from different files. On by default
when used interactively.

=item B<-C [I<NUM>]>, B<--context[=I<NUM>]>

Print I<NUM> lines (default 2) of context around matching lines.
You can specify zero lines of context to override another context
specified in an ackrc.

=item B<-c>, B<--count>

Suppress normal output; instead print a count of matching lines for
each input file.  If B<-l> is in effect, it will only show the
number of lines for each file that has lines matching.  Without
B<-l>, some line counts may be zeroes.

If combined with B<-h> (B<--no-filename>) ack outputs only one total
count.

=item B<--[no]color>, B<--[no]colour>

B<--color> highlights the matching text.  B<--nocolor> suppresses
the color.  This is on by default unless the output is redirected.

On Windows, this option is off by default unless the
L<Win32::Console::ANSI> module is installed or the C<ACK_PAGER_COLOR>
environment variable is used.

=item B<--color-filename=I<color>>

Sets the color to be used for filenames.

=item B<--color-match=I<color>>

Sets the color to be used for matches.

=item B<--color-colno=I<color>>

Sets the color to be used for column numbers.

=item B<--color-lineno=I<color>>

Sets the color to be used for line numbers.

=item B<--[no]column>

Show the column number of the first match.  This is helpful for
editors that can place your cursor at a given position.

=item B<--create-ackrc>

Dumps the default ack options to standard output.  This is useful for
when you want to customize the defaults.

=item B<--dump>

Writes the list of options loaded and where they came from to standard
output.  Handy for debugging.

=item B<--[no]env>

B<--noenv> disables all environment processing. No F<.ackrc> is
read and all environment variables are ignored. By default, F<ack>
considers F<.ackrc> and settings in the environment.

=item B<--flush>

B<--flush> flushes output immediately.  This is off by default
unless ack is running interactively (when output goes to a pipe or
file).

=item B<-f>

Only print the files that would be searched, without actually doing
any searching.  PATTERN must not be specified, or it will be taken
as a path to search.

=item B<--files-from=I<FILE>>

The list of files to be searched is specified in I<FILE>.  The list of
files are separated by newlines.  If I<FILE> is C<->, the list is loaded
from standard input.

Note that the list of files is B<not> filtered in any way.  If you
add C<--type=html> in addition to C<--files-from>, the C<--type> will
be ignored.


=item B<--[no]filter>

Forces ack to act as if it were receiving input via a pipe.

=item B<--[no]follow>

Follow or don't follow symlinks, other than whatever starting files
or directories were specified on the command line.

This is off by default.

=item B<-g I<PATTERN>>

Print searchable files where the relative path + filename matches
I<PATTERN>.

Note that

    ack -g foo

is exactly the same as

    ack -f | ack foo

This means that just as ack will not search, for example, F<.jpg>
files, C<-g> will not list F<.jpg> files either.  ack is not intended
to be a general-purpose file finder.

Note also that if you have C<-i> in your .ackrc that the filenames
to be matched will be case-insensitive as well.

This option can be combined with B<--color> to make it easier to
spot the match.

=item B<--[no]group>

B<--group> groups matches by file name.  This is the default
when used interactively.

B<--nogroup> prints one result per line, like grep.  This is the
default when output is redirected.

=item B<-H>, B<--with-filename>

Print the filename for each match. This is the default unless searching
a single explicitly specified file.

=item B<-h>, B<--no-filename>

Suppress the prefixing of filenames on output when multiple files are
searched.

=item B<--[no]heading>

Print a filename heading above each file's results.  This is the default
when used interactively.

=item B<--help>

Print a short help statement.

=item B<--help-types>

Print all known types.

=item B<--help-colors>

Print a chart of various color combinations.

=item B<--help-rgb-colors>

Like B<--help-colors> but with more precise RGB colors.

=item B<-i>, B<--ignore-case>

Ignore case distinctions in PATTERN.  Overrides B<--smart-case> and B<-I>.

=item B<-I>, B<--no-ignore-case>

Turns on case distinctions in PATTERN.  Overrides B<--smart-case> and B<-i>.

=item B<--ignore-ack-defaults>

Tells ack to completely ignore the default definitions provided with ack.
This is useful in combination with B<--create-ackrc> if you I<really> want
to customize ack.

=item B<--[no]ignore-dir=I<DIRNAME>>, B<--[no]ignore-directory=I<DIRNAME>>

Ignore directory (as CVS, .svn, etc are ignored). May be used
multiple times to ignore multiple directories. For example, mason
users may wish to include B<--ignore-dir=data>. The B<--noignore-dir>
option allows users to search directories which would normally be
ignored (perhaps to research the contents of F<.svn/props> directories).

The I<DIRNAME> must always be a simple directory name. Nested
directories like F<foo/bar> are NOT supported. You would need to
specify B<--ignore-dir=foo> and then no files from any foo directory
are taken into account by ack unless given explicitly on the command
line.

=item B<--ignore-file=I<FILTER:ARGS>>

Ignore files matching I<FILTER:ARGS>.  The filters are specified
identically to file type filters as seen in L</"Defining your own types">.

=item B<-k>, B<--known-types>

Limit selected files to those with types that ack knows about.

=item B<-l>, B<--files-with-matches>

Only print the filenames of matching files, instead of the matching text.

=item B<-L>, B<--files-without-matches>

Only print the filenames of files that do I<NOT> match.

=item B<--match I<PATTERN>>

Specify the I<PATTERN> explicitly. This is helpful if you don't want to put the
regex as your first argument, e.g. when executing multiple searches over the
same set of files.

    # search for foo and bar in given files
    ack file1 t/file* --match foo
    ack file1 t/file* --match bar

=item B<-m=I<NUM>>, B<--max-count=I<NUM>>

Print only I<NUM> matches out of each file.  If you want to stop ack
after printing the first match of any kind, use the B<-1> options.

=item B<--man>

Print this manual page.

=item B<-n>, B<--no-recurse>

No descending into subdirectories.

=item B<--not=PATTERN>

Specifies a I<PATTERN> that must NOT me true on a given line for a match to
occur. This option can be repeated.

If you want to find all the lines with "dogs" but not if "cats" or "fish"
appear on the line, use:

    ack dogs --not cats --not fish

Note that the options that affect "dogs" also affect "cats" and "fish", so
if you have

    ack -i -w dogs --not cats

the the search for both "dogs" and "cats" will be case-insensitive and be
word-limited.

=item B<-o>

Show only the part of each line matching PATTERN (turns off text
highlighting).  This is exactly the same as C<--output=$&>.

=item B<--output=I<expr>>

Output the evaluation of I<expr> for each line (turns off text
highlighting). If PATTERN matches more than once then a line is
output for each non-overlapping match.

I<expr> may contain the strings "\n", "\r" and "\t", which will be
expanded to their corresponding characters line feed, carriage return
and tab, respectively.

I<expr> may also contain the following Perl special variables:

=over 4

=item C<$1> through C<$9>

The subpattern from the corresponding set of capturing parentheses.
If your pattern is C<(.+) and (.+)>, and the string is "this and
that', then C<$1> is "this" and C<$2> is "that".

=item C<$_>

The contents of the line in the file.

=item C<$.>

The number of the line in the file.

=item C<$&>, C<$`> and C<$'>

C<$&> is the the string matched by the pattern, C<$`> is what
precedes the match, and C<$'> is what follows it.  If the pattern
is C<gra(ph|nd)> and the string is "lexicographic", then C<$&> is
"graph", C<$`> is "lexico" and C<$'> is "ic".

Use of these variables in your output will slow down the pattern
matching.

=item C<$+>

The match made by the last parentheses that matched in the pattern.
For example, if your pattern is C<Version: (.+)|Revision: (.+)>,
then C<$+> will contain whichever set of parentheses matched.

=item C<$f>

C<$f> is available, in C<--output> only, to insert the filename.
This is a stand-in for the discovered C<$filename> usage in old C<< ack2 --output >>,
which is disallowed with C<ack3> improved security.

The intended usage is to provide the grep or compile-error syntax needed for editor/IDE go-to-line integration,
e.g. C<--output=$f:$.:$_> or C<--output=$f\t$.\t$&>

=back

=item B<--pager=I<program>>, B<--nopager>

B<--pager> directs ack's output through I<program>.  This can also be specified
via the C<ACK_PAGER> and C<ACK_PAGER_COLOR> environment variables.

Using --pager does not suppress grouping and coloring like piping
output on the command-line does.

B<--nopager> cancels any setting in F<~/.ackrc>, C<ACK_PAGER> or C<ACK_PAGER_COLOR>.
No output will be sent through a pager.

=item B<--passthru>

Prints all lines, whether or not they match the expression.  Highlighting
will still work, though, so it can be used to highlight matches while
still seeing the entire file, as in:

    # Watch a log file, and highlight a certain IP address.
    $ tail -f ~/access.log | ack --passthru 123.45.67.89

=item B<--print0>

Only works in conjunction with B<-f>, B<-g>, B<-l> or B<-c>, options
that only list filenames.  The filenames are output separated with a
null byte instead of the usual newline. This is helpful when dealing
with filenames that contain whitespace, e.g.

    # Remove all files of type HTML.
    ack -f --html --print0 | xargs -0 rm -f

=item B<-p[N]>, B<--proximate[=N]>

Groups together match lines that are within N lines of each other.
This is useful for visually picking out matches that appear close
to other matches.

For example, if you got these results without the C<--proximate> option,

    15: First match
    18: Second match
    19: Third match
    37: Fourth match

they would look like this with C<--proximate=1>

    15: First match

    18: Second match
    19: Third match

    37: Fourth match

and this with C<--proximate=3>.

    15: First match
    18: Second match
    19: Third match

    37: Fourth match

If N is omitted, N is set to 1.

=item B<-P>

Negates the effect of the B<--proximate> option.  Shortcut for B<--proximate=0>.

=item B<-Q>, B<--literal>

Quote all metacharacters in PATTERN, it is treated as a literal.

=item B<-r>, B<-R>, B<--recurse>

Recurse into sub-directories. This is the default and just here for
compatibility with grep. You can also use it for turning B<--no-recurse> off.

=item B<--range-start=PATTERN>, B<--range-end=PATTERN>

Specifies patterns that mark the start and end of a range.  See
L<MATCHING IN A RANGE OF LINES> for details.

=item B<-s>

Suppress error messages about nonexistent or unreadable files.  This is taken
from fgrep.

=item B<-S>, B<--[no]smart-case>, B<--no-smart-case>

Ignore case in the search strings if PATTERN contains no uppercase
characters. This is similar to C<smartcase> in the vim text editor.
The options overrides B<-i> and B<-I>.

B<-S> is a synonym for B<--smart-case>.

B<-i> always overrides this option.

=item B<--sort-files>

Sorts the found files lexicographically.  Use this if you want your file
listings to be deterministic between runs of I<ack>.

=item B<--show-types>

Outputs the filetypes that ack associates with each file.

Works with B<-f> and B<-g> options.

=item B<-t TYPE>, B<--type=TYPE>, B<--TYPE>

Specify the types of files to include in the search.
TYPE is a filetype, like I<perl> or I<xml>.  B<--type=perl> can
also be specified as B<--perl>, although this is deprecated.

Type inclusions can be repeated and are ORed together.

See I<ack --help-types> for a list of valid types.

=item B<-T TYPE>, B<--type=noTYPE>, B<--noTYPE>

Specifies the type of files to exclude from the search.  B<--type=noperl>
can be done as B<--noperl>, although this is deprecated.

If a file is of both type "foo" and "bar", specifying both B<--type=foo>
and B<--type=nobar> will exclude the file, because an exclusion takes
precedence over an inclusion.

=item B<--type-add I<TYPE>:I<FILTER>:I<ARGS>>

Files with the given ARGS applied to the given FILTER
are recognized as being of (the existing) type TYPE.
See also L</"Defining your own types">.

=item B<--type-set I<TYPE>:I<FILTER>:I<ARGS>>

Files with the given ARGS applied to the given FILTER are recognized as
being of type TYPE. This replaces an existing definition for type TYPE.  See
also L</"Defining your own types">.

=item B<--type-del I<TYPE>>

The filters associated with TYPE are removed from Ack, and are no longer considered
for searches.

=item B<--[no]underline>

Turns on underlining of matches, where "underlining" is printing a line of
carets under the match.

    $ ack -u foo
    peanuts.txt
    17: Come kick the football you fool
                      ^^^          ^^^
    623: Price per square foot
                          ^^^

This is useful if you're dumping the results of an ack run into a text
file or printer that doesn't support ANSI color codes.

The setting of underline does not affect highlighting of matches.

=item B<-v>, B<--invert-match>

Invert match: select non-matching lines.

=item B<--version>

Display version and copyright information.

=item B<-w>, B<--word-regexp>

Force PATTERN to match only whole words.

=item B<-x>

An abbreviation for B<--files-from=->. The list of files to search are read
from standard input, with one line per file.

Note that the list of files is B<not> filtered in any way.  If you add
C<--type=html> in addition to C<-x>, the C<--type> will be ignored.

=item B<-1>

Stops after reporting first match of any kind.  This is different
from B<--max-count=1> or B<-m1>, where only one match per file is
shown.  Also, B<-1> works with B<-f> and B<-g>, where B<-m> does
not.

=item B<--thpppt>

Display the all-important Bill The Cat logo.  Note that the exact
spelling of B<--thpppppt> is not important.  It's checked against
a regular expression.

=item B<--bar>

Check with the admiral for traps.

=item B<--cathy>

Chocolate, Chocolate, Chocolate!

=back

=head1 THE .ackrc FILE

The F<.ackrc> file contains command-line options that are prepended
to the command line before processing.  Multiple options may live
on multiple lines.  Lines beginning with a # are ignored.  A F<.ackrc>
might look like this:

    # Always sort the files
    --sort-files

    # Always color, even if piping to another program
    --color

    # Use "less -r" as my pager
    --pager=less -r

Note that arguments with spaces in them do not need to be quoted,
as they are not interpreted by the shell. Basically, each I<line>
in the F<.ackrc> file is interpreted as one element of C<@ARGV>.

F<ack> looks in several locations for F<.ackrc> files; the searching
process is detailed in L</"ACKRC LOCATION SEMANTICS">.  These
files are not considered if B<--noenv> is specified on the command line.

=head1 Defining your own types

ack allows you to define your own types in addition to the predefined
types. This is done with command line options that are best put into
an F<.ackrc> file - then you do not have to define your types over and
over again. In the following examples the options will always be shown
on one command line so that they can be easily copy & pasted.

File types can be specified both with the the I<--type=xxx> option,
or the file type as an option itself.  For example, if you create
a filetype of "cobol", you can specify I<--type=cobol> or simply
I<--cobol>.  File types must be at least two characters long.  This
is why the C language is I<--cc> and the R language is I<--rr>.

I<ack --perl foo> searches for foo in all perl files. I<ack --help-types>
tells you, that perl files are files ending
in .pl, .pm, .pod or .t. So what if you would like to include .xs
files as well when searching for --perl files? I<ack --type-add perl:ext:xs --perl foo>
does this for you. B<--type-add> appends
additional extensions to an existing type.

If you want to define a new type, or completely redefine an existing
type, then use B<--type-set>. I<ack --type-set eiffel:ext:e,eiffel> defines
the type I<eiffel> to include files with
the extensions .e or .eiffel. So to search for all eiffel files
containing the word Bertrand use I<ack --type-set eiffel:ext:e,eiffel --eiffel Bertrand>.
As usual, you can also write B<--type=eiffel>
instead of B<--eiffel>. Negation also works, so B<--noeiffel> excludes
all eiffel files from a search. Redefining also works: I<ack --type-set cc:ext:c,h>
and I<.xs> files no longer belong to the type I<cc>.

When defining your own types in the F<.ackrc> file you have to use
the following:

  --type-set=eiffel:ext:e,eiffel

or writing on separate lines

  --type-set
  eiffel:ext:e,eiffel

The following does B<NOT> work in the F<.ackrc> file:

  --type-set eiffel:ext:e,eiffel

In order to see all currently defined types, use I<--help-types>, e.g.
I<ack --type-set backup:ext:bak --type-add perl:ext:perl --help-types>

In addition to filtering based on extension, ack offers additional
filter types.  The generic syntax is
I<--type-set TYPE:FILTER:ARGS>; I<ARGS> depends on the value
of I<FILTER>.

=over 4

=item is:I<FILENAME>

I<is> filters match the target filename exactly.  It takes exactly one
argument, which is the name of the file to match.

Example:

    --type-set make:is:Makefile

=item ext:I<EXTENSION>[,I<EXTENSION2>[,...]]

I<ext> filters match the extension of the target file against a list
of extensions.  No leading dot is needed for the extensions.

Example:

    --type-set perl:ext:pl,pm,t

=item match:I<PATTERN>

I<match> filters match the target filename against a regular expression.
The regular expression is made case-insensitive for the search.

Example:

    --type-set make:match:/(gnu)?makefile/

=item firstlinematch:I<PATTERN>

I<firstlinematch> matches the first line of the target file against a
regular expression.  Like I<match>, the regular expression is made
case insensitive.

Example:

    --type-add perl:firstlinematch:/perl/

=back

=head1 ACK COLORS

ack allows customization of the colors it uses when presenting matches
onscreen.  It uses the colors available in Perl's L<Term::ANSIColor>
module, which provides the following listed values. Note that case does not
matter when using these values.

There are four different colors ack uses:

    Aspect      Option              Env. variable       Default
    --------    -----------------   ------------------  ---------------
    filename    --color-filename    ACK_COLOR_FILENAME  black on_yellow
    match       --color-match       ACK_COLOR_MATCH     bold green
    line no.    --color-lineno      ACK_COLOR_LINENO    bold yellow
    column no.  --color-colno       ACK_COLOR_COLNO     bold yellow

The column number column is only used if the column number is shown because
of the --column option.

Colors may be specified by command-line option, such as
C<ack --color-filename='red on_white'>, or by setting an environment
variable, such as C<ACK_COLOR_FILENAME='red on_white'>.  Options for colors
can be set in your ACKRC file (See "THE .ackrc FILE").

ack can understand the following colors for the foreground:

    black red green yellow blue magenta cyan white

The optional background color is specified by prepending "on_" to one of
the foreground colors:

    on_black on_red on_green on_yellow on_blue on_magenta on_cyan on_white

Each of the foreground colors can be modified with the following
attributes, which may or may not be supported by your terminal:

    bold faint italic underline blink reverse concealed

Any combinations of modifiers can be added to the foreground color. If your
terminal supports it, and you enjoy visual punishment, you can specify:

    ack --color-filename="blink italic underline bold red on_yellow"

For charts of the colors and what they look like, run C<ack --help-colors>
and C<ack --help-rgb-colors>.

If the eight standard colors, in their bold, faint and unmodified states,
aren't enough for you to choose from, you can also specify colors by their
RGB values.  They are specified as "rgbXYZ" where X, Y, and Z are values
between 0 and 5 giving the intensity of red, green and blue, respectively.
Therefore, "rgb500" is pure red, "rgb505" is purple, and so on.

Background colors can be specified with the "on_" prefix prepended on an
RGB color, so that "on_rgb505" would be a purple background.

The modifier attributes of blink, italic, underscore and so on may or may
not work on the RGB colors.

For a chart of the 216 possible RGB colors, run C<ack --help-rgb-colors>.

=head1 ENVIRONMENT VARIABLES

For commonly-used ack options, environment variables can make life
much easier.  These variables are ignored if B<--noenv> is specified
on the command line.

=over 4

=item ACKRC

Specifies the location of the user's F<.ackrc> file.  If this file doesn't
exist, F<ack> looks in the default location.

=item ACK_COLOR_COLNO

Color specification for the column number in ack's output.  By default, the
column number is not shown.  You have to enable it with the B<--column>
option.  See the section "ack Colors" above.

=item ACK_COLOR_FILENAME

Color specification for the filename in ack's output.  See the section "ack
Colors" above.

=item ACK_COLOR_LINENO

Color specification for the line number in ack's output.  See the section
"ack Colors" above.

=item ACK_COLOR_MATCH

Color specification for the matched text in ack's output.  See the section
"ack Colors" above.

=item ACK_PAGER

Specifies a pager program, such as C<more>, C<less> or C<most>, to which
ack will send its output.

Using C<ACK_PAGER> does not suppress grouping and coloring like
piping output on the command-line does, except that on Windows
ack will assume that C<ACK_PAGER> does not support color.

C<ACK_PAGER_COLOR> overrides C<ACK_PAGER> if both are specified.

=item ACK_PAGER_COLOR

Specifies a pager program that understands ANSI color sequences.
Using C<ACK_PAGER_COLOR> does not suppress grouping and coloring
like piping output on the command-line does.

If you are not on Windows, you never need to use C<ACK_PAGER_COLOR>.

=back

=head1 ACK & OTHER TOOLS

=head2 Simple vim integration

F<ack> integrates easily with the Vim text editor. Set this in your
F<.vimrc> to use F<ack> instead of F<grep>:

    set grepprg=ack\ -k

That example uses C<-k> to search through only files of the types ack
knows about, but you may use other default flags. Now you can search
with F<ack> and easily step through the results in Vim:

  :grep Dumper perllib

=head2 Editor integration

Many users have integrated ack into their preferred text editors.
For details and links, see L<https://beyondgrep.com/more-tools/>.

=head2 Shell and Return Code

For greater compatibility with I<grep>, I<ack> in normal use returns
shell return or exit code of 0 only if something is found and 1 if
no match is found.

(Shell exit code 1 is C<$?=256> in perl with C<system> or backticks.)

The I<grep> code 2 for errors is not used.

If C<-f> or C<-g> are specified, then 0 is returned if at least one
file is found.  If no files are found, then 1 is returned.

=cut

=head1 DEBUGGING ACK PROBLEMS

If ack gives you output you're not expecting, start with a few simple steps.

=head2 Try it with B<--noenv>

Your environment variables and F<.ackrc> may be doing things you're
not expecting, or forgotten you specified.  Use B<--noenv> to ignore
your environment and F<.ackrc>.

=head2 Use B<-f> to see what files have been selected for searching

Ack's B<-f> was originally added as a debugging tool.  If ack is
not finding matches you think it should find, run F<ack -f> to see
what files have been selected.  You can also add the C<--show-types>
options to show the type of each file selected.

=head2 Use B<--dump>

This lists the ackrc files that are loaded and the options loaded
from them.  You may be loading an F<.ackrc> file that you didn't know
you were loading.

=head1 ACKRC LOCATION SEMANTICS

Ack can load its configuration from many sources.  The following list
specifies the sources Ack looks for configuration files; each one
that is found is loaded in the order specified here, and
each one overrides options set in any of the sources preceding
it.  (For example, if I set --sort-files in my user ackrc, and
--nosort-files on the command line, the command line takes
precedence)

=over 4

=item *

Defaults are loaded from App::Ack::ConfigDefaults.  This can be omitted
using C<--ignore-ack-defaults>.

=item * Global ackrc

Options are then loaded from the global ackrc.  This is located at
C</etc/ackrc> on Unix-like systems.

Under Windows XP and earlier, the global ackrc is at
C<C:\Documents and Settings\All Users\Application Data\ackrc>

Under Windows Vista/7, the global ackrc is at
C<C:\ProgramData\ackrc>

The C<--noenv> option prevents all ackrc files from being loaded.

=item * User ackrc

Options are then loaded from the user's ackrc.  This is located at
C<$HOME/.ackrc> on Unix-like systems.

Under Windows XP and earlier, the user's ackrc is at
C<C:\Documents and Settings\$USER\Application Data\ackrc>.

Under Windows Vista/7, the user's ackrc is at
C<C:\Users\$USER\AppData\Roaming\ackrc>.

If you want to load a different user-level ackrc, it may be specified
with the C<$ACKRC> environment variable.

The C<--noenv> option prevents all ackrc files from being loaded.

=item * Project ackrc

Options are then loaded from the project ackrc.  The project ackrc is
the first ackrc file with the name C<.ackrc> or C<_ackrc>, first searching
in the current directory, then the parent directory, then the grandparent
directory, etc.  This can be omitted using C<--noenv>.

=item * --ackrc

The C<--ackrc> option may be included on the command line to specify an
ackrc file that can override all others.  It is consulted even if C<--noenv>
is present.

=item * Command line

Options are then loaded from the command line.

=back

=head1 BUGS & ENHANCEMENTS

ack is based at GitHub at L<https://github.com/beyondgrep/ack3>

Please report any bugs or feature requests to the issues list at
GitHub: L<https://github.com/beyondgrep/ack3/issues>.

Please include the operating system that you're using; the output of
the command C<ack --version>; and any customizations in your F<.ackrc>
you may have.

To suggest enhancements, please submit an issue at
L<https://github.com/beyondgrep/ack3/issues>.  Also read the
F<DEVELOPERS.md> file in the ack code repository.

Also, feel free to discuss your issues on the ack mailing
list at L<https://groups.google.com/group/ack-users>.

=head1 SUPPORT

Support for and information about F<ack> can be found at:

=over 4

=item * The ack homepage

L<https://beyondgrep.com/>

=item * Source repository

L<https://github.com/beyondgrep/ack3>

=item * The ack issues list at GitHub

L<https://github.com/beyondgrep/ack3/issues>

=item * The ack announcements mailing list

L<https://groups.google.com/group/ack-announcement>

=item * The ack users' mailing list

L<https://groups.google.com/group/ack-users>

=item * The ack development mailing list

L<https://groups.google.com/group/ack-users>

=back

=head1 COMMUNITY

There are ack mailing lists and a Slack channel for ack.  See
L<https://beyondgrep.com/community/> for details.

=head1 FAQ

This is the Frequently Asked Questions list for ack.

=head2 Can I stop using grep now?

Many people find I<ack> to be better than I<grep> as an everyday tool
99% of the time, but don't throw I<grep> away, because there are times
you'll still need it.  For example, you might be looking through huge
log files and not using regular expressions.  In that case, I<grep>
will probably perform better.

=head2 Why isn't ack finding a match in (some file)?

First, take a look and see if ack is even looking at the file.  ack is
intelligent in what files it will search and which ones it won't, but
sometimes that can be surprising.

Use the C<-f> switch, with no regex, to see a list of files that ack
will search for you.  If your file doesn't show up in the list of files
that C<ack -f> shows, then ack never looks in it.

=head2 Wouldn't it be great if F<ack> did search & replace?

No, ack will always be read-only.  Perl has a perfectly good way
to do search & replace in files, using the C<-i>, C<-p> and C<-n>
switches.

You can certainly use ack to select your files to update.  For
example, to change all "foo" to "bar" in all PHP files, you can do
this from the Unix shell:

    $ perl -i -p -e's/foo/bar/g' $(ack -f --php)

=head2 Can I make ack recognize F<.xyz> files?

Yes!  Please see L</"Defining your own types"> in the ack manual.

=head2 Will you make ack recognize F<.xyz> files by default?

We might, depending on how widely-used the file format is.

Submit an issue at in the GitHub issue queue at
L<https://github.com/beyondgrep/ack3/issues>.  Explain what the file format
is, where we can find out more about it, and what you have been using
in your F<.ackrc> to support it.

Please do not bother creating a pull request.  The code for filetypes
is trivial compared to the rest of the process we go through.

=head2 Why is it called ack if it's called ack-grep?

The name of the program is "ack".  Some packagers have called it
"ack-grep" when creating packages because there's already a package
out there called "ack" that has nothing to do with this ack.

I suggest you make a symlink named F<ack> that points to F<ack-grep>
because one of the crucial benefits of ack is having a name that's
so short and simple to type.

To do that, run this with F<sudo> or as root:

   ln -s /usr/bin/ack-grep /usr/bin/ack

Alternatively, you could use a shell alias:

    # bash/zsh
    alias ack=ack-grep

    # csh
    alias ack ack-grep

=head2 What does F<ack> mean?

Nothing.  I wanted a name that was easy to type and that you could
pronounce as a single syllable.

=head2 Can I do multi-line regexes?

No, ack does not support regexes that match multiple lines.  Doing
so would require reading in the entire file at a time.

If you want to see lines near your match, use the C<--A>, C<--B>
and C<--C> switches for displaying context.

=head2 Why is ack telling me I have an invalid option when searching for C<+foo>?

ack treats command line options beginning with C<+> or C<-> as options; if you
would like to search for these, you may prefix your search term with C<--> or
use the C<--match> option.  (However, don't forget that C<+> is a regular
expression metacharacter!)

=head2 Why does C<"ack '.{40000,}'"> fail?  Isn't that a valid regex?

The Perl language limits the repetition quantifier to 32K.  You
can search for C<.{32767}> but not C<.{32768}>.

=head2 Ack does "X" and shouldn't, should it?

We try to remain as close to grep's behavior as possible, so when in
doubt, see what grep does!  If there's a mismatch in functionality there,
please submit an issue to GitHub, and/or bring it up on the ack-users
mailing list.

=cut

=head1 ACKNOWLEDGEMENTS

How appropriate to have I<ack>nowledgements!

Thanks to everyone who has contributed to ack in any way, including
Thomas Gossler,
Kieran Mace,
Volker Glave,
Axel Beckert,
Eric Pement,
Gabor Szabo,
Frieder Bluemle,
Grzegorz Kaczmarczyk,
Dan Book,
Tomasz Konojacki,
Salomon Smeke,
M. Scott Ford,
Anders Eriksson,
H.Merijn Brand,
Duke Leto,
Gerhard Poul,
Ethan Mallove,
Marek Kubica,
Ray Donnelly,
Nikolaj Schumacher,
Ed Avis,
Nick Morrott,
Austin Chamberlin,
Varadinsky,
SE<eacute>bastien FeugE<egrave>re,
Jakub Wilk,
Pete Houston,
Stephen Thirlwall,
Jonah Bishop,
Chris Rebert,
Denis Howe,
RaE<uacute>l GundE<iacute>n,
James McCoy,
Daniel Perrett,
Steven Lee,
Jonathan Perret,
Fraser Tweedale,
RaE<aacute>l GundE<aacute>n,
Steffen Jaeckel,
Stephan Hohe,
Michael Beijen,
Alexandr Ciornii,
Christian Walde,
Charles Lee,
Joe McMahon,
John Warwick,
David Steinbrunner,
Kara Martens,
Volodymyr Medvid,
Ron Savage,
Konrad Borowski,
Dale Sedivic,
Michael McClimon,
Andrew Black,
Ralph Bodenner,
Shaun Patterson,
Ryan Olson,
Shlomi Fish,
Karen Etheridge,
Olivier Mengue,
Matthew Wild,
Scott Kyle,
Nick Hooey,
Bo Borgerson,
Mark Szymanski,
Marq Schneider,
Packy Anderson,
JR Boyens,
Dan Sully,
Ryan Niebur,
Kent Fredric,
Mike Morearty,
Ingmar Vanhassel,
Eric Van Dewoestine,
Sitaram Chamarty,
Adam James,
Richard Carlsson,
Pedro Melo,
AJ Schuster,
Phil Jackson,
Michael Schwern,
Jan Dubois,
Christopher J. Madsen,
Matthew Wickline,
David Dyck,
Jason Porritt,
Jjgod Jiang,
Thomas Klausner,
Uri Guttman,
Peter Lewis,
Kevin Riggle,
Ori Avtalion,
Torsten Blix,
Nigel Metheringham,
GE<aacute>bor SzabE<oacute>,
Tod Hagan,
Michael Hendricks,
E<AElig>var ArnfjE<ouml>rE<eth> Bjarmason,
Piers Cawley,
Stephen Steneker,
Elias Lutfallah,
Mark Leighton Fisher,
Matt Diephouse,
Christian Jaeger,
Bill Sully,
Bill Ricker,
David Golden,
Nilson Santos F. Jr,
Elliot Shank,
Merijn Broeren,
Uwe Voelker,
Rick Scott,
Ask BjE<oslash>rn Hansen,
Jerry Gay,
Will Coleda,
Mike O'Regan,
Slaven ReziE<0x107>,
Mark Stosberg,
David Alan Pisoni,
Adriano Ferreira,
James Keenan,
Leland Johnson,
Ricardo Signes,
Pete Krawczyk and
Rob Hoelz.

=head1 AUTHOR

Andy Lester, C<< <andy at petdance.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2005-2023 Andy Lester.

This program is free software; you can redistribute it and/or modify
it under the terms of the Artistic License v2.0.

See https://www.perlfoundation.org/artistic-license-20.html or the LICENSE.md
file that comes with the ack distribution.

=cut

1;
