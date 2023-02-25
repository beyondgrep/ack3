package App::Ack::ConfigLoader;

use strict;
use warnings;
use 5.010;

use App::Ack ();
use App::Ack::ConfigDefault ();
use App::Ack::ConfigFinder ();
use App::Ack::Filter ();
use App::Ack::Filter::Collection ();
use App::Ack::Filter::Default ();
use App::Ack::Filter::IsPath ();
use File::Spec 3.00 ();
use Getopt::Long 2.38 ();
use Text::ParseWords 3.1 ();

sub configure_parser {
    my @opts = @_;

    my @standard = qw(
        default
        bundling
        no_auto_help
        no_auto_version
        no_ignore_case
    );
    Getopt::Long::Configure( @standard, @opts );

    return;
}


sub _generate_ignore_dir {
    my ( $option_name, $opt ) = @_;

    my $is_inverted = $option_name =~ /^--no/;

    return sub {
        my ( undef, $dir ) = @_;

        $dir = _remove_directory_separator( $dir );
        if ( $dir !~ /:/ ) {
            $dir = 'is:' . $dir;
        }

        my ( $filter_type, $args ) = split /:/, $dir, 2;

        if ( $filter_type eq 'firstlinematch' ) {
            App::Ack::die( qq{Invalid filter specification "$filter_type" for option '$option_name'} );
        }

        my $filter = App::Ack::Filter->create_filter($filter_type, split(/,/, $args));
        my $collection;

        my $previous_inversion_matches = $opt->{idirs} && !($is_inverted xor $opt->{idirs}[-1]->is_inverted());

        if ( $previous_inversion_matches ) {
            $collection = $opt->{idirs}[-1];

            if ( $is_inverted ) {
                # This relies on invert of an inverted filter to return the original.
                $collection = $collection->invert();
            }
        }
        else {
            $collection = App::Ack::Filter::Collection->new();
            push @{ $opt->{idirs} }, $is_inverted ? $collection->invert() : $collection;
        }

        $collection->add($filter);

        if ( $filter_type eq 'is' ) {
            $collection->add(App::Ack::Filter::IsPath->new($args));
        }
    };
}


sub _remove_directory_separator {
    my $path = shift;

    state $dir_sep_chars = $App::Ack::is_windows ? quotemeta( '\\/' ) : quotemeta( File::Spec->catfile( '', '' ) );

    $path =~ s/[$dir_sep_chars]$//;

    return $path;
}


sub _process_filter_spec {
    my ( $spec ) = @_;

    if ( $spec =~ /^(\w+):(\w+):(.*)/ ) {
        my ( $type_name, $ext_type, $arguments ) = ( $1, $2, $3 );

        return ( $type_name,
            App::Ack::Filter->create_filter($ext_type, split(/,/, $arguments)) );
    }
    elsif ( $spec =~ /^(\w+)=(.*)/ ) { # Check to see if we have ack1-style argument specification.
        my ( $type_name, $extensions ) = ( $1, $2 );

        my @extensions = split(/,/, $extensions);
        foreach my $extension ( @extensions ) {
            $extension =~ s/^[.]//;
        }

        return ( $type_name, App::Ack::Filter->create_filter('ext', @extensions) );
    }
    else {
        App::Ack::die( "Invalid filter specification '$spec'" );
    }
}


sub _uninvert_filter {
    my ( $opt, @filters ) = @_;

    return unless defined $opt->{filters} && @filters;

    # Loop through all the registered filters.  If we hit one that
    # matches this extension and it's inverted, we need to delete it from
    # the options.
    for ( my $i = 0; $i < @{ $opt->{filters} }; $i++ ) {
        my $opt_filter = @{ $opt->{filters} }[$i];

        # XXX Do a real list comparison? This just checks string equivalence.
        if ( $opt_filter->is_inverted() && "$opt_filter->{filter}" eq "@filters" ) {
            splice @{ $opt->{filters} }, $i, 1;
            $i--;
        }
    }

    return;
}


sub _process_filetypes {
    my ( $opt, $arg_sources ) = @_;

    my %additional_specs;

    my $add_spec = sub {
        my ( undef, $spec ) = @_;

        my ( $name, $filter ) = _process_filter_spec($spec);

        push @{ $App::Ack::mappings{$name} }, $filter;

        $additional_specs{$name . '!'} = sub {
            my ( undef, $value ) = @_;

            my @filters = @{ $App::Ack::mappings{$name} };
            if ( not $value ) {
                @filters = map { $_->invert() } @filters;
            }
            else {
                _uninvert_filter( $opt, @filters );
            }

            push @{ $opt->{'filters'} }, @filters;
        };
    };

    my $set_spec = sub {
        my ( undef, $spec ) = @_;

        my ( $name, $filter ) = _process_filter_spec($spec);

        $App::Ack::mappings{$name} = [ $filter ];

        $additional_specs{$name . '!'} = sub {
            my ( undef, $value ) = @_;

            my @filters = @{ $App::Ack::mappings{$name} };
            if ( not $value ) {
                @filters = map { $_->invert() } @filters;
            }

            push @{ $opt->{'filters'} }, @filters;
        };
    };

    my $delete_spec = sub {
        my ( undef, $name ) = @_;

        delete $App::Ack::mappings{$name};
        delete $additional_specs{$name . '!'};
    };

    my %type_arg_specs = (
        'type-add=s' => $add_spec,
        'type-set=s' => $set_spec,
        'type-del=s' => $delete_spec,
    );

    configure_parser( 'no_auto_abbrev', 'pass_through' );
    foreach my $source (@{$arg_sources}) {
        my $args = $source->{contents};

        if ( ref($args) ) {
            # $args are modified in place, so no need to munge $arg_sources
            Getopt::Long::GetOptionsFromArray( $args, %type_arg_specs );
        }
        else {
            ( undef, $source->{contents} ) =
                Getopt::Long::GetOptionsFromString( $args, %type_arg_specs );
        }
    }

    $additional_specs{'k|known-types'} = sub {
        my @filters = map { @{$_} } values(%App::Ack::mappings);

        push @{ $opt->{'filters'} }, @filters;
    };

    return \%additional_specs;
}


sub get_arg_spec {
    my ( $opt, $extra_specs ) = @_;

=begin Adding-Options

    *** IF YOU ARE MODIFYING ACK PLEASE READ THIS ***

    If you plan to add a new option to ack, please make sure of
    the following:

    * Your new option has a test underneath the t/ directory.
    * Your new option is explained when a user invokes ack --help.
      (See App::Ack::show_help)
    * Your new option is explained when a user invokes ack --man.
      (See the POD at the end of ./ack)
    * Add your option to t/config-loader.t
    * Add your option to t/Util.pm#get_expected_options
    * Add your option's description and aliases to dev/generate-completion-scripts.pl
    * Go through the list of options already available, and consider
      whether your new option can be considered mutex with another option.

=end Adding-Options

=cut

    sub _type_handler {
        my ( $getopt, $value ) = @_;

        my $cb_value = 1;
        if ( $value =~ s/^no// ) {
            $cb_value = 0;
        }

        my $callback;
        {
            no warnings;
            $callback = $extra_specs->{ $value . '!' };
        }

        if ( $callback ) {
            $callback->( $getopt, $cb_value );
        }
        else {
            App::Ack::die( "Unknown type '$value'" );
        }

        return;
    }

    $opt->{not} = [];

    return {
        1                   => sub { $opt->{1} = $opt->{m} = 1 },
        'A|after-context:-1'  => sub { shift; $opt->{A} = _context_value(shift) },
        'B|before-context:-1' => sub { shift; $opt->{B} = _context_value(shift) },
        'C|context:-1'        => sub { shift; $opt->{B} = $opt->{A} = _context_value(shift) },
        'break!'            => \$opt->{break},
        'c|count'           => \$opt->{c},
        'color|colour!'     => \$opt->{color},
        'color-match=s'     => \$ENV{ACK_COLOR_MATCH},
        'color-filename=s'  => \$ENV{ACK_COLOR_FILENAME},
        'color-colno=s'     => \$ENV{ACK_COLOR_COLNO},
        'color-lineno=s'    => \$ENV{ACK_COLOR_LINENO},
        'column!'           => \$opt->{column},
        'create-ackrc'      => sub { say for ( '--ignore-ack-defaults', App::Ack::ConfigDefault::options() ); exit; },
        'debug'             => \$opt->{debug},
        'env!'              => sub {
            my ( undef, $value ) = @_;

            if ( !$value ) {
                $opt->{noenv_seen} = 1;
            }
        },
        f                   => \$opt->{f},
        'files-from=s'      => \$opt->{files_from},
        'filter!'           => \$App::Ack::is_filter_mode,
        flush               => sub { $| = 1 },
        'follow!'           => \$opt->{follow},
        g                   => \$opt->{g},
        'group!'            => sub { shift; $opt->{heading} = $opt->{break} = shift },
        'heading!'          => \$opt->{heading},
        'h|no-filename'     => \$opt->{h},
        'H|with-filename'   => \$opt->{H},
        'i|ignore-case'     => sub { $opt->{i} = 1; $opt->{S} = 0; },
        'I|no-ignore-case'  => sub { $opt->{i} = 0; $opt->{S} = 0; },
        'ignore-directory|ignore-dir=s' => _generate_ignore_dir('--ignore-dir', $opt),
        'ignore-file=s'     => sub {
            my ( undef, $file ) = @_;

            my ( $filter_type, $args ) = split /:/, $file, 2;

            my $filter = App::Ack::Filter->create_filter($filter_type, split(/,/, $args//''));

            if ( !$opt->{ifiles} ) {
                $opt->{ifiles} = App::Ack::Filter::Collection->new();
            }
            $opt->{ifiles}->add($filter);
        },
        'l|files-with-matches'
                            => \$opt->{l},
        'L|files-without-matches'
                            => \$opt->{L},
        'm|max-count=i'     => \$opt->{m},
        'match=s'           => \$opt->{regex},
        'n|no-recurse'      => \$opt->{n},
        o                   => sub { $opt->{output} = '$&' },
        'output=s'          => \$opt->{output},
        'pager:s'           => sub {
            my ( undef, $value ) = @_;

            $opt->{pager} = $value || $ENV{PAGER};
        },
        'noignore-directory|noignore-dir=s' => _generate_ignore_dir('--noignore-dir', $opt),
        'nopager'           => sub { $opt->{pager} = undef },
        'not=s'             => $opt->{not},
        'passthru'          => \$opt->{passthru},
        'print0'            => \$opt->{print0},
        'p|proximate:1'     => \$opt->{p},
        'P'                 => sub { $opt->{p} = 0 },
        'Q|literal'         => \$opt->{Q},
        'r|R|recurse'       => sub { $opt->{n} = 0 },
        'range-start=s'     => \$opt->{range_start},
        'range-end=s'       => \$opt->{range_end},
        'range-invert!'     => \$opt->{range_invert},
        's'                 => \$opt->{s},
        'show-types'        => \$opt->{show_types},
        'S|smart-case!'     => sub { my (undef,$value) = @_; $opt->{S} = $value; $opt->{i} = 0 if $value; },
        'sort-files'        => \$opt->{sort_files},
        't|type=s'          => \&_type_handler,
        'T=s'               => sub { my ($getopt,$value) = @_; $value="no$value"; _type_handler($getopt,$value); },
        'underline!'        => \$opt->{underline},
        'v|invert-match'    => \$opt->{v},
        'w|word-regexp'     => \$opt->{w},
        'x'                 => sub { $opt->{files_from} = '-' },

        'help'              => sub { App::Ack::show_help(); exit; },
        'help-types'        => sub { App::Ack::show_help_types(); exit; },
        'help-colors'       => sub { App::Ack::show_help_colors(); exit; },
        'help-rgb-colors'   => sub { App::Ack::show_help_rgb(); exit; },
        $extra_specs ? %{$extra_specs} : (),
    }; # arg_specs
}


sub _context_value {
    my $val = shift;

    # Contexts default to 2.
    return (!defined($val) || ($val < 0)) ? 2 : $val;
}


sub _process_other {
    my ( $opt, $extra_specs, $arg_sources ) = @_;

    my $argv_source;
    my $is_help_types_active;

    foreach my $source (@{$arg_sources}) {
        if ( $source->{name} eq 'ARGV' ) {
            $argv_source = $source->{contents};
            last;
        }
    }

    if ( $argv_source ) { # This *should* always be true, but you never know...
        configure_parser( 'pass_through' );
        Getopt::Long::GetOptionsFromArray( [ @{$argv_source} ],
            'help-types' => \$is_help_types_active,
        );
    }

    my $arg_specs = get_arg_spec( $opt, $extra_specs );

    configure_parser();
    foreach my $source (@{$arg_sources}) {
        my ( $source_name, $args ) = @{$source}{qw/name contents/};

        my $args_for_source = { %{$arg_specs} };

        if ( $source->{is_ackrc} ) {
            my $illegal = sub {
                my $name = shift;
                App::Ack::die( "Option --$name is forbidden in .ackrc files." );
            };

            $args_for_source = {
                %{$args_for_source},
                'output=s' => $illegal,
                'match=s'  => $illegal,
            };
        }
        if ( $source->{project} ) {
            my $illegal = sub {
                my $name = shift;
                App::Ack::die( "Option --$name is forbidden in project .ackrc files." );
            };

            $args_for_source = {
                %{$args_for_source},
                'pager:s' => $illegal,
            };
        }

        my $ret;
        if ( ref($args) ) {
            $ret = Getopt::Long::GetOptionsFromArray( $args, %{$args_for_source} );
        }
        else {
            ( $ret, $source->{contents} ) =
                Getopt::Long::GetOptionsFromString( $args, %{$args_for_source} );
        }
        if ( !$ret ) {
            if ( !$is_help_types_active ) {
                my $where = $source_name eq 'ARGV' ? 'on command line' : "in $source_name";
                App::Ack::die( "Invalid option $where" );
            }
        }
        if ( $opt->{noenv_seen} ) {
            App::Ack::die( "--noenv found in $source_name" );
        }
    }

    # XXX We need to check on a -- in the middle of a non-ARGV source

    return;
}


sub _explode_sources {
    my ( $sources ) = @_;

    my @new_sources;

    my %opt;
    my $arg_spec = get_arg_spec( \%opt, {} );

    my $dummy_sub = sub {};
    my $add_type = sub {
        my ( undef, $arg ) = @_;

        if ( $arg =~ /(\w+)=/) {
            $arg_spec->{$1} = $dummy_sub;
        }
        else {
            ( $arg ) = split /:/, $arg;
            $arg_spec->{$arg} = $dummy_sub;
        }
    };

    my $del_type = sub {
        my ( undef, $arg ) = @_;

        delete $arg_spec->{$arg};
    };

    configure_parser( 'pass_through' );
    foreach my $source (@{$sources}) {
        my ( $name, $options ) = @{$source}{qw/name contents/};
        if ( ref($options) ne 'ARRAY' ) {
            $source->{contents} = $options =
                [ Text::ParseWords::shellwords($options) ];
        }

        for my $j ( 0 .. @{$options}-1 ) {
            next unless $options->[$j] =~ /^-/;
            my @chunk = ( $options->[$j] );
            push @chunk, $options->[$j] while ++$j < @{$options} && $options->[$j] !~ /^-/;
            $j--;

            my @copy = @chunk;
            Getopt::Long::GetOptionsFromArray( [@chunk],
                'type-add=s' => $add_type,
                'type-set=s' => $add_type,
                'type-del=s' => $del_type,
                %{$arg_spec}
            );

            push @new_sources, {
                name     => $name,
                contents => \@copy,
            };
        }
    }

    return \@new_sources;
}


sub _compare_opts {
    my ( $a, $b ) = @_;

    my $first_a = $a->[0];
    my $first_b = $b->[0];

    $first_a =~ s/^--?//;
    $first_b =~ s/^--?//;

    return $first_a cmp $first_b;
}


sub _dump_options {
    my ( $sources ) = @_;

    $sources = _explode_sources($sources);

    my %opts_by_source;
    my @source_names;

    foreach my $source (@{$sources}) {
        my $name = $source->{name};
        if ( not $opts_by_source{$name} ) {
            $opts_by_source{$name} = [];
            push @source_names, $name;
        }
        push @{$opts_by_source{$name}}, $source->{contents};
    }

    foreach my $name (@source_names) {
        my $contents = $opts_by_source{$name};

        say $name;
        say '=' x length($name);
        say '  ', join(' ', @{$_}) for sort { _compare_opts($a, $b) } @{$contents};
    }

    return;
}


sub _remove_default_options_if_needed {
    my ( $sources ) = @_;

    my $default_index;

    foreach my $index ( 0 .. $#{$sources} ) {
        if ( $sources->[$index]{'name'} eq 'Defaults' ) {
            $default_index = $index;
            last;
        }
    }

    return $sources unless defined $default_index;

    my $should_remove = 0;

    configure_parser( 'no_auto_abbrev', 'pass_through' );

    foreach my $index ( $default_index + 1 .. $#{$sources} ) {
        my $args = $sources->[$index]->{contents};

        if (ref($args)) {
            Getopt::Long::GetOptionsFromArray( $args,
                'ignore-ack-defaults' => \$should_remove,
            );
        }
        else {
            ( undef, $sources->[$index]{contents} ) = Getopt::Long::GetOptionsFromString( $args,
                'ignore-ack-defaults' => \$should_remove,
            );
        }
    }

    return $sources unless $should_remove;

    my @copy = @{$sources};
    splice @copy, $default_index, 1;
    return \@copy;
}


sub process_args {
    my $arg_sources = \@_;

    my %opt = (
        pager => $ENV{ACK_PAGER_COLOR} || $ENV{ACK_PAGER},
    );

    $arg_sources = _remove_default_options_if_needed($arg_sources);

    # Check for --dump early.
    foreach my $source (@{$arg_sources}) {
        if ( $source->{name} eq 'ARGV' ) {
            my $dump;
            configure_parser( 'pass_through' );
            Getopt::Long::GetOptionsFromArray( $source->{contents},
                'dump' => \$dump,
            );
            if ( $dump ) {
                _dump_options($arg_sources);
                exit(0);
            }
        }
    }

    my $type_specs = _process_filetypes(\%opt, $arg_sources);

    _check_for_mutex_options( $type_specs );

    _process_other(\%opt, $type_specs, $arg_sources);
    while ( @{$arg_sources} ) {
        my $source = shift @{$arg_sources};
        my $args = $source->{contents};

        # All of our sources should be transformed into an array ref
        if ( ref($args) ) {
            my $source_name = $source->{name};
            if ( $source_name eq 'ARGV' ) {
                @ARGV = @{$args};
            }
            elsif (@{$args}) {
                App::Ack::die( "Source '$source_name' has extra arguments!" );
            }
        }
        else {
            App::Ack::die( 'The impossible has occurred!' );
        }
    }
    my $filters = ($opt{filters} ||= []);

    # Throw the default filter in if no others are selected.
    if ( not grep { !$_->is_inverted() } @{$filters} ) {
        push @{$filters}, App::Ack::Filter::Default->new();
    }
    return \%opt;
}


sub retrieve_arg_sources {
    my @arg_sources;

    my $noenv;
    my $ackrc;

    configure_parser( 'no_auto_abbrev', 'pass_through' );
    Getopt::Long::GetOptions(
        'noenv'   => \$noenv,
        'ackrc=s' => \$ackrc,
    );

    my @files;

    if ( !$noenv ) {
        my $finder = App::Ack::ConfigFinder->new;
        @files  = $finder->find_config_files;
    }
    if ( $ackrc ) {
        # We explicitly use open so we get a nice error message.
        # XXX This is a potential race condition!.
        if ( open my $fh, '<', $ackrc ) {
            close $fh;
        }
        else {
            App::Ack::die( "Unable to load ackrc '$ackrc': $!" );
        }
        push( @files, { path => $ackrc } );
    }

    push @arg_sources, {
        name     => 'Defaults',
        contents => [ App::Ack::ConfigDefault::options_clean() ],
    };

    foreach my $file ( @files) {
        my @lines = read_rcfile($file->{path});
        if ( @lines ) {
            push @arg_sources, {
                name     => $file->{path},
                contents => \@lines,
                project  => $file->{project},
                is_ackrc => 1,
            };
        }
    }

    push @arg_sources, {
        name     => 'ARGV',
        contents => [ @ARGV ],
    };

    return @arg_sources;
}


sub read_rcfile {
    my $file = shift;

    return unless defined $file && -e $file;

    my @lines;

    open( my $fh, '<', $file ) or App::Ack::die( "Unable to read $file: $!" );
    while ( defined( my $line = <$fh> ) ) {
        chomp $line;
        $line =~ s/^\s+//;
        $line =~ s/\s+$//;

        next if $line eq '';
        next if $line =~ /^\s*#/;

        push( @lines, $line );
    }
    close $fh or App::Ack::die( "Unable to close $file: $!" );

    return @lines;
}


# Verifies no mutex options were passed.  Dies if they were.
sub _check_for_mutex_options {
    my $type_specs = shift;

    my $mutex = mutex_options();

    my ($raw,$used) = _options_used( $type_specs );

    my @used = sort { lc $a cmp lc $b } keys %{$used};

    for my $i ( @used ) {
        for my $j ( @used ) {
            next if $i eq $j;
            if ( $mutex->{$i}{$j} ) {
                my $x = $raw->[ $used->{$i} ];
                my $y = $raw->[ $used->{$j} ];
                App::Ack::die( "Options '$x' and '$y' can't be used together." );
            }
        }
    }

    return;
}


# Processes the command line option and returns a hash of the options that were
# used on the command line, using their full name.  "--prox" shows up in the hash as "--proximate".
sub _options_used {
    my $type_specs = shift;

    my %dummy_opt;
    my $real_spec = get_arg_spec( \%dummy_opt, $type_specs );

    # The real argument parsing doesn't check for --type-add, --type-del or --type-set because
    # they get removed by the argument processing.  We have to account for them here.
    my $sub_dummy = sub {};
    $real_spec = {
        %{$real_spec},
        'type-add=s'          => $sub_dummy,
        'type-del=s'          => $sub_dummy,
        'type-set=s'          => $sub_dummy,
        'ignore-ack-defaults' => $sub_dummy,
    };

    my %parsed;
    my @raw;
    my %spec_capture_parsed;
    my %spec_capture_raw;

=pod

We have to build two argument specs.

To populate the C<%parsed> hash: Capture the arguments that the user has
passed in, as parsed by the Getopt::Long::GetOptions function. Aliases are converted
down to their short options. If a user passes "--proximate", Getopt::Long
converts that to "-p" and we store it as "-p".

To populate the C<@raw> array: Capture the arguments raw, without having
been converted to their short options.  If a user passes "--proximate",
we store it in C<@raw> as "--proximate".

=cut

    # Capture the %parsed hash.
    CAPTURE_PARSED: {
        my $parsed_pos = 0;
        my $sub_count = sub {
            my $arg = shift;
            $arg = "$arg";
            $parsed{$arg} = $parsed_pos++;
        };
        %spec_capture_parsed = (
            '<>' => sub { $parsed_pos++ },  # Bump forward one pos for non-options.
            map { $_ => $sub_count } keys %{$real_spec}
        );
    }

    # Capture the @raw array.
    CAPTURE_RAW: {
        my $raw_pos = 0;
        %spec_capture_raw = (
            '<>' => sub { $raw_pos++ }, # Bump forward one pos for non-options.
        );

        my $sub_count = sub {
            my $arg = shift;

            $arg = "$arg";
            $raw[$raw_pos] = length($arg) == 1 ? "-$arg" : "--$arg";
            $raw_pos++;
        };

        for my $opt_spec ( keys %{$real_spec} ) {
            my $negatable;
            my $type;
            my $default;

            $negatable = ($opt_spec =~ s/!$//);

            if ( $opt_spec =~ s/(=[si])$// ) {
                $type = $1;
            }
            if ( $opt_spec =~ s/(:.+)$// ) {
                $default = $1;
            }

            my @aliases = split( /\|/, $opt_spec );
            for my $alias ( @aliases ) {
                $alias .= $type    if defined $type;
                $alias .= $default if defined $default;
                $alias .= '!'      if $negatable;

                $spec_capture_raw{$alias} = $sub_count;
            }
        }
    }

    # Parse @ARGV twice, once with each capture spec.
    configure_parser( 'pass_through' );   # Ignore invalid options.
    Getopt::Long::GetOptionsFromArray( [@ARGV], %spec_capture_raw );
    Getopt::Long::GetOptionsFromArray( [@ARGV], %spec_capture_parsed );

    return (\@raw,\%parsed);
}


sub mutex_options {
    # This list is machine-generated by dev/crank-mutex.  Do not modify it by hand.

    return {
        1 => {
            m => 1,
            passthru => 1,
        },
        A => {
            L => 1,
            c => 1,
            f => 1,
            g => 1,
            l => 1,
            o => 1,
            output => 1,
            p => 1,
            passthru => 1,
        },
        B => {
            L => 1,
            c => 1,
            f => 1,
            g => 1,
            l => 1,
            o => 1,
            output => 1,
            p => 1,
            passthru => 1,
        },
        C => {
            L => 1,
            c => 1,
            f => 1,
            g => 1,
            l => 1,
            o => 1,
            output => 1,
            p => 1,
            passthru => 1,
        },
        H => {
            L => 1,
            f => 1,
            g => 1,
            l => 1,
        },
        I => {
            f => 1,
        },
        L => {
            A => 1,
            B => 1,
            C => 1,
            H => 1,
            L => 1,
            break => 1,
            c => 1,
            column => 1,
            f => 1,
            g => 1,
            group => 1,
            h => 1,
            heading => 1,
            l => 1,
            'no-filename' => 1,
            o => 1,
            output => 1,
            p => 1,
            passthru => 1,
            'show-types' => 1,
            v => 1,
            'with-filename' => 1,
        },
        break => {
            L => 1,
            c => 1,
            f => 1,
            g => 1,
            l => 1,
        },
        c => {
            A => 1,
            B => 1,
            C => 1,
            L => 1,
            break => 1,
            column => 1,
            f => 1,
            g => 1,
            group => 1,
            heading => 1,
            m => 1,
            o => 1,
            output => 1,
            p => 1,
            passthru => 1,
        },
        column => {
            L => 1,
            c => 1,
            f => 1,
            g => 1,
            l => 1,
            o => 1,
            output => 1,
            passthru => 1,
            v => 1,
        },
        f => {
            A => 1,
            B => 1,
            C => 1,
            H => 1,
            I => 1,
            L => 1,
            break => 1,
            c => 1,
            column => 1,
            f => 1,
            'files-from' => 1,
            g => 1,
            group => 1,
            h => 1,
            heading => 1,
            i => 1,
            l => 1,
            m => 1,
            match => 1,
            o => 1,
            output => 1,
            p => 1,
            passthru => 1,
            'smart-case' => 1,
            u => 1,
            v => 1,
            x => 1,
        },
        'files-from' => {
            f => 1,
            g => 1,
            x => 1,
        },
        g => {
            A => 1,
            B => 1,
            C => 1,
            H => 1,
            L => 1,
            break => 1,
            c => 1,
            column => 1,
            f => 1,
            'files-from' => 1,
            g => 1,
            group => 1,
            h => 1,
            heading => 1,
            l => 1,
            m => 1,
            match => 1,
            not => 1,
            o => 1,
            output => 1,
            p => 1,
            passthru => 1,
            u => 1,
            x => 1,
        },
        group => {
            L => 1,
            c => 1,
            f => 1,
            g => 1,
            l => 1,
        },
        h => {
            L => 1,
            f => 1,
            g => 1,
            l => 1,
        },
        heading => {
            L => 1,
            c => 1,
            f => 1,
            g => 1,
            l => 1,
        },
        i => {
            f => 1,
        },
        l => {
            A => 1,
            B => 1,
            C => 1,
            H => 1,
            L => 1,
            break => 1,
            column => 1,
            f => 1,
            g => 1,
            group => 1,
            h => 1,
            heading => 1,
            l => 1,
            'no-filename' => 1,
            o => 1,
            output => 1,
            p => 1,
            passthru => 1,
            'show-types' => 1,
            'with-filename' => 1,
        },
        m => {
            1 => 1,
            c => 1,
            f => 1,
            g => 1,
            passthru => 1,
        },
        match => {
            f => 1,
            g => 1,
        },
        'no-filename' => {
            L => 1,
            l => 1,
        },
        not => {
            g => 1,
        },
        o => {
            A => 1,
            B => 1,
            C => 1,
            L => 1,
            c => 1,
            column => 1,
            f => 1,
            g => 1,
            l => 1,
            o => 1,
            output => 1,
            p => 1,
            passthru => 1,
            'show-types' => 1,
            v => 1,
        },
        output => {
            A => 1,
            B => 1,
            C => 1,
            L => 1,
            c => 1,
            column => 1,
            f => 1,
            g => 1,
            l => 1,
            o => 1,
            output => 1,
            p => 1,
            passthru => 1,
            'show-types' => 1,
            u => 1,
            v => 1,
        },
        p => {
            A => 1,
            B => 1,
            C => 1,
            L => 1,
            c => 1,
            f => 1,
            g => 1,
            l => 1,
            o => 1,
            output => 1,
            p => 1,
            passthru => 1,
        },
        passthru => {
            1 => 1,
            A => 1,
            B => 1,
            C => 1,
            L => 1,
            c => 1,
            column => 1,
            f => 1,
            g => 1,
            l => 1,
            m => 1,
            o => 1,
            output => 1,
            p => 1,
            v => 1,
        },
        'show-types' => {
            L => 1,
            l => 1,
            o => 1,
            output => 1,
        },
        'smart-case' => {
            f => 1,
        },
        u => {
            f => 1,
            g => 1,
            output => 1,
        },
        v => {
            L => 1,
            column => 1,
            f => 1,
            o => 1,
            output => 1,
            passthru => 1,
        },
        'with-filename' => {
            L => 1,
            l => 1,
        },
        x => {
            f => 1,
            'files-from' => 1,
            g => 1,
        },
    };

}   # End of mutex_options()


1; # End of App::Ack::ConfigLoader
