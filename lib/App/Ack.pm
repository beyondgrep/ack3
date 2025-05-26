package App::Ack;

use warnings;
use strict;

=head1 NAME

App::Ack

=head1 DESCRIPTION

A container for functions for the ack program.

=cut

our $VERSION;
our $COPYRIGHT;
BEGIN {
    $VERSION = 'v3.8.2'; # Check https://beyondgrep.com/ for updates
    $COPYRIGHT = 'Copyright 2005-2025 Andy Lester.';
}
our $STANDALONE = 0;
our $ORIGINAL_PROGRAM_NAME;

our $fh;

BEGIN {
    $fh = *STDOUT;
}


our %types;
our %type_wanted;
our %mappings;
our %ignore_dirs;

our $is_filter_mode;
our $output_to_pipe;

our $is_windows;

our $debug_nopens = 0;

# Line ending, changes to "\0" if --print0.
our $ors = "\n";

BEGIN {
    # These have to be checked before any filehandle diddling.
    $output_to_pipe  = not -t *STDOUT;
    $is_filter_mode = -p STDIN;

    $is_windows      = ($^O eq 'MSWin32');
}

=head1 SYNOPSIS

If you want to know about the F<ack> program, see the F<ack> file itself.

No user-serviceable parts inside.  F<ack> is all that should use this.

=head1 FUNCTIONS

=head2 warn( @_ )

Put out an ack-specific warning.

=cut

sub warn {
    return CORE::warn( _my_program(), ': ', @_, "\n" );
}

=head2 die( @msgs )

Die in an ack-specific way.

=cut

sub die {
    return CORE::die( _my_program(), ': ', @_, "\n" );
}

sub _my_program {
    require File::Basename;
    return File::Basename::basename( $0 );
}


sub thpppt {
    my $y = q{_   /|,\\'!.x',=(www)=,   U   };
    $y =~ tr/,x!w/\nOo_/;

    App::Ack::print( "$y ack $_[0]!\n" );
    exit 0;
}

sub ackbar {
    my $x;
    $x = <<'_BAR';
 6?!I'7!I"?%+!
 3~!I#7#I"7#I!?!+!="+"="+!:!
 2?#I!7!I!?#I!7!I"+"=%+"=#
 1?"+!?*+!=#~"=!+#?"="+!
 0?"+!?"I"?&+!="~!=!~"=!+%="+"
 /I!+!?)+!?!+!=$~!=!~!="+!="+"?!="?!
 .?%I"?%+%='?!=#~$="
 ,,!?%I"?(+$=$~!=#:"~$:!~!
 ,I!?!I!?"I"?!+#?"+!?!+#="~$:!~!:!~!:!,!:!,":#~!
 +I!?&+!="+!?#+$=!~":!~!:!~!:!,!:#,!:!,%:"
 *+!I!?!+$=!+!=!+!?$+#=!~":!~":#,$:",#:!,!:!
 *I!?"+!?!+!=$+!?#+#=#~":$,!:",!:!,&:"
 )I!?$=!~!=#+"?!+!=!+!=!~!="~!:!~":!,'.!,%:!~!
 (=!?"+!?!=!~$?"+!?!+!=#~"=",!="~$,$.",#.!:!=!
 (I"+"="~"=!+&=!~"=!~!,!~!+!=!?!+!?!=!I!?!+"=!.",!.!,":!
 %I$?!+!?!=%+!~!+#~!=!~#:#=!~!+!~!=#:!,%.!,!.!:"
 $I!?!=!?!I!+!?"+!=!~!=!~!?!I!?!=!+!=!~#:",!~"=!~!:"~!=!:",&:" '-/
 $?!+!I!?"+"=!+"~!,!:"+#~#:#,"=!~"=!,!~!,!.",!:".!:! */! !I!t!'!s! !a! !g!r!e!p!!! !/!
 $+"=!+!?!+"~!=!:!~!:"I!+!,!~!=!:!~!,!:!,$:!~".&:"~!,# (-/
 %~!=!~!=!:!.!+"~!:!,!.!,!~!=!:$.!,":!,!.!:!~!,!:!=!.#="~!,!:" ./!
 %=!~!?!+"?"+!=!~",!.!:!?!~!.!:!,!:!,#.!,!:","~!:!=!~!=!:",!~! ./!
 %+"~":!~!=#~!:!~!,!.!~!:",!~!=!~!.!:!,!.",!:!,":!=":!.!,!:!7! -/!
 %~",!:".#:!=!:!,!:"+!:!~!:!.!,!~!,!.#,!.!,$:"~!,":"~!=! */!
 &=!~!=#+!=!~",!.!:",#:#,!.",+:!,!.",!=!+!?!
 &~!=!~!=!~!:"~#:",!.!,#~!:!.!+!,!.",$.",$.#,!+!I!?!
 &~!="~!:!~":!~",!~!=!~":!,!:!~!,!:!,&.$,#."+!?!I!?!I!
 &~!=!~!=!+!,!:!~!:!=!,!:!~&:$,!.!,".!,".!,#."~!+!?$I!
 &~!=!~!="~!=!:!~":!,!~%:#,!:",!.!,#.",#I!7"I!?!+!?"I"
 &+!I!7!:#~"=!~!:!,!:"~$.!=!.!,!~!,$.#,!~!7!I#?!+!?"I"7!
 %7#?!+!~!:!=!~!=!~":!,!:"~":#.!,)7#I"?"I!7&
 %7#I!=":!=!~!:"~$:"~!:#,!:!,!:!~!:#,!7#I!?#7)
 $7$+!,!~!=#~!:!~!:!~$:#,!.!~!:!=!,":!7#I"?#7+=!?!
 $7#I!~!,!~#=!~!:"~!:!,!:!,#:!=!~",":!7$I!?#I!7*+!=!+"
 "I!7$I!,":!,!.!=":$,!:!,$:$7$I!+!?"I!7+?"I!7!I!7!,!
 !,!7%I!:",!."~":!,&.!,!:!~!I!7$I!+!?"I!7,?!I!7',!
 !7(,!.#~":!,%.!,!7%I!7!?#I"7,+!?!7*
7+:!,!~#,"=!7'I!?#I"7/+!7+
77I!+!7!?!7!I"71+!7,
_BAR

    return _pic_decode($x);
}

sub cathy {
    my $x = <<'CATHY';
 0+!--+!
 0|! "C!H!O!C!O!L!A!T!E!!! !|!
 0|! "C!H!O!C!O!L!A!T!E!!! !|!
 0|! "C!H!O!C!O!L!A!T!E!!! !|!
 0|! $A"C!K!!! $|!
 0+!--+!
 6\! 1:!,!.! !
 7\! /.!M!~!Z!M!~!
 8\! /~!D! "M! !
 4.! $\! /M!~!.!8! +.!M# 4
 0,!.! (\! .~!M!N! ,+!I!.!M!.! 3
 /?!O!.!M!:! '\! .O!.! +~!Z!=!N!.! 4
 ..! !D!Z!.!Z!.! '\! 9=!M".! 6
 /.! !.!~!M".! '\! 8~! 9
 4M!.! /.!7!N!M!.! F
 4.! &:!M! !N"M# !M"N!M! #D!M&=! =
 :M!7!M#:! !~!M!7!,!$!M!:! #.! !O!N!.!M!:!M# ;
 8Z!M"~!N!$!D!.!N!?! !I!N!.! (?!M! !M!,!D!M".! 9
 (?!Z!M!N!:! )=!M!O!8!.!M!+!M! !M!,! !O!M! +,!M!.!M!~!Z!N!M!:! &:!~! 0
 &8!7!.!~!M"D!M!,! &M!?!=!8! !M!,!O! !M!+! !+!O!.!M! $M#~! !.!8!M!Z!.!M! !O!M"Z! %:!~!M!Z!M!Z!.! +
 &:!M!7!,! *M!.!Z!M! !8"M!.!M!~! !.!M!.!=! #~!8!.!M! !7!M! "N!Z#I! !D!M!,!M!.! $."M!,! !M!.! *
 2$!O! "N! !.!M!I! !7" "M! "+!O! !~!M! !d!O!.!7!I!M!.! !.!O!=!M!.! !M",!M!.! %.!$!O!D! +
 1~!O! "M!+! !8!$! "M! "?!O! %Z!8!D!M!?!8!I!O!7!M! #M!.!M! "M",!M! 4
 07!~! ".!8! !.!M! "I!+! !.!M! &Z!D!.!7!=!M! !:!.!M! #:!8"+! !.!+!8! !8! 3
 /~!M! #N! !~!M!$! !.!M! !.!M" &~!M! "~!M!O! "D! $M! !8! "M!,!M!+!D!.! 1
 #.! #?!M!N!.! #~!O! $M!.!7!$! "?" !?!~!M! '7!8!?!M!.!+!M"O! $?"$!D! !.!O! !$!7!I!.! 0
 $,!M!:!O!?! ".! !?!=! $=!:!O! !M! "M! !M! !+!$! (.! +.!M! !M!.! !8! !+"Z!~! $:!M!$! !.! '
 #.!8!.!I!$! $7!I! %M" !=!M! !~!M!D! "7!I! .I!O! %?!=!,!D! !,!M! !D!~!8!~! %D!M! (
 #.!M"?! $=!O! %=!N! "8!.! !Z!M! #M!~! (M!:! #.!M" &O! !M!.! !?!,! !8!.!N!~! $8!N!M!,!.! %
 *$!O! &M!,! "O! !.!M!.! #M! (~!M( &O!.! !7! "M! !.!M!.!M!,! #.!M! !M! &
 )=!8!.! $.!M!O!.! "$!.!I!N! !I!M# (7!M(I! %D"Z!M! "=!I! "M! !M!:! #~!D! '
 )D! &8!N!:! ".!O! !M!="M! "M! (7!M) %." !M!D!."M!.! !$!=! !M!,! +
 (M! &+!.!M! #Z!7!O!M!.!~!8! +,!M#D!?!M#D! #.!Z!M#,!Z!?! !~!N! "N!.! !M! +
 'D!:! %$!D! !?! #M!Z! !8!.! !M"?!7!?!7! '+!I!D! !?!O!:!M!:! ":!M!:! !M!7".!M! "8!+! !:!D! !.!M! *
 %.!O!:! $.!O!+! !D!.! #M! "M!.!+!N!I!Z! "7!M!N!M!N!?!I!7!Z!=!M'D"~! #M!.!8!$! !:! !.!M! "N!?! !,!O! )
 !.!?!M!:!M!I! %8!,! "M!.! #M! "N! !M!.! !M!.! !+!~! !.!M!.! ':!M! $M! $M!Z!$! !M!.! "D! "M! "?!M! (
 !7!8! !+!I! ".! "$!=! ":!$! "+! !M!.! !O! !M!I!M".! !=!~! ",!O! '=!M! $$!,! #N!:! ":!8!.! !D!~! !,!M!.! !:!M!.! &
 !:!,!.! &Z" #D! !.!8!."M!.! !8!?!Z!M!.!M! #Z!~! !?!M!Z!.! %~!O!.!8!$!N!8!O!I!:!~! !+! #M!.! !.!M!.! !+!M! ".!~!M!+! $
 !.! 'D!I! #?!M!.!M!,! !.!Z! !.!8! #M&O!I!?! (~!I!M"." !M!Z!.! !M!N!.! "+!$!.! "M!.! !M!?!.! "8!M! $
 (O!8! $M! !M!.! ".!:! !+!=! #M! #.!M! !+" *$!M":!.! !M!~! "M!7! #M! #7!Z! "M"$!M!.! !.! #
 '$!Z! #.!7!+!M! $.!,! !+!:! #N! #.!M!.!+!M! +D!M! #=!N! ":!O! #=!M! #Z!D! $M!I! %
 $,! ".! $.!M" %$!.! !?!~! "+!7!." !.!M!,! !M! *,!N!M!.$M!?! "D!,! #M!.! #N! +
 ,M!Z! &M! "I!,! "M! %I!M! !?!=!.! (Z!8!M! $:!M!.! !,!M! $D! #.!M!.! )
 +8!O! &.!8! "I!,! !~!M! &N!M! !M!D! '?!N!O!." $?!7! "?!~! #M!.! #I!D!.! (
 3M!,! "N!.! !D" &.!+!M!.! !M":!.":!M!7!M!D! 'M!.! "M!.! "M!,! $I! )
 3I! #M! "M!,! !:! &.!M" ".!,! !.!$!M!I! #.! !:! !.!M!?! "N!+! ".! /
 1M!,! #.!M!8!M!=!.! +~!N"O!Z"~! *+!M!.! "M! 2
 0.!M! &M!.! 8:! %.!M!Z! "M!=! *O!,! %
 0?!$! &N! )." .,! %."M! ":!M!.! 0
 0N!:! %?!O! #.! ..! &,! &.!D!,! "N!I! 0
CATHY
    return _pic_decode($x);
}

sub _pic_decode {
    my($compressed) = @_;
    $compressed =~ s/(.)(.)/$1x(ord($2)-32)/eg;
    App::Ack::print( $compressed );
    exit 0;
}

=head2 show_help()

Dumps the help page to the user.

=cut

sub show_help {
    App::Ack::print( <<"END_OF_HELP" );
Usage: ack [OPTION]... PATTERN [FILES OR DIRECTORIES]

Search for PATTERN in each source file in the tree from the current
directory on down.  If any files or directories are specified, then
only those files and directories are checked.  ack may also search
STDIN, but only if no file or directory arguments are specified,
or if one of them is "-".

Default switches may be specified in an .ackrc file. If you want no dependency
on the environment, turn it off with --noenv.

File select actions:
  -f                            Only print the files selected, without
                                searching.  The PATTERN must not be specified.
  -g                            Same as -f, but only select files matching
                                PATTERN.

File listing actions:
  -l, --files-with-matches      Print filenames with at least one match
  -L, --files-without-matches   Print filenames with no matches
  -c, --count                   Print filenames and count of matching lines

Searching:
  -i, --ignore-case             Ignore case distinctions in PATTERN
  -S, --[no]smart-case          Ignore case distinctions in PATTERN,
                                only if PATTERN contains no upper case.
                                Ignored if -i or -I are specified.
  -I, --no-ignore-case          Turns on case-sensitivity in PATTERN.
                                Negates -i and --smart-case.
  -v, --invert-match            Invert match: select non-matching lines
  -w, --word-regexp             Force PATTERN to match only whole words
  -Q, --literal                 Quote all metacharacters; PATTERN is literal
  --range-start PATTERN         Specify PATTERN as the start of a match range.
  --range-end PATTERN           Specify PATTERN as the end of a match range.
  --match PATTERN               Specify PATTERN explicitly. Typically omitted.
  --and PATTERN                 Specifies PATTERN that MUST also be found on
                                the line for a match to occur. Repeatable.
  --or PATTERN                  Specifies PATTERN that MAY also be found on
                                the line for a match to occur. Repeatable.
  --not PATTERN                 Specifies PATTERN that must NOT be found on
                                the line for a match to occur. Repeatable.

Search output:
  --output=expr                 Output the evaluation of expr for each line
                                (turns off text highlighting)
  -o                            Show only the part of a line matching PATTERN
                                Same as --output='\$&'
  --passthru                    Print all lines, whether matching or not
  -m, --max-count=NUM           Stop searching in each file after NUM matches
  -1                            Stop searching after one match of any kind
  -H, --with-filename           Print the filename for each match (default:
                                on unless explicitly searching a single file)
  -h, --no-filename             Suppress the prefixing filename on output
  --[no]column                  Show the column number of the first match

  -A NUM, --after-context=NUM   Print NUM lines of trailing context after
                                matching lines.
  -B NUM, --before-context=NUM  Print NUM lines of leading context before
                                matching lines.
  -C [NUM], --context[=NUM]     Print NUM lines (default 2) of output context.

  --print0                      Print null byte as separator between filenames,
                                only works with -f, -g, -l, -L or -c.

  -s                            Suppress error messages about nonexistent or
                                unreadable files.


File presentation:
  --pager=COMMAND               Pipes all ack output through COMMAND.  For
                                example, --pager="less -R".  Ignored if output
                                is redirected.
  --nopager                     Do not send output through a pager.  Cancels
                                any setting in ~/.ackrc, ACK_PAGER or
                                ACK_PAGER_COLOR.
  --[no]heading                 Print a filename heading above each file's
                                results.  (default: on when used interactively)
  --[no]break                   Print a break between results from different
                                files.  (default: on when used interactively)
  --group                       Same as --heading --break
  --nogroup                     Same as --noheading --nobreak
  -p, --proximate=LINES         Separate match output with blank lines unless
                                they are within LINES lines from each other.
  -P, --proximate=0             Negates --proximate.
  --[no]underline               Print a line of carets under the matched text.
  --[no]color, --[no]colour     Highlight the matching text (default: on unless
                                output is redirected, or on Windows)
  --color-filename=COLOR
  --color-match=COLOR
  --color-colno=COLOR
  --color-lineno=COLOR          Set the color for filenames, matches, line and
                                column numbers.
  --help-colors                 Show a list of possible color combinations.
  --help-rgb-colors             Show a list of advanced RGB colors.
  --flush                       Flush output immediately, even when ack is used
                                non-interactively (when output goes to a pipe or
                                file).


File finding:
  --sort-files                  Sort the found files lexically.
  --show-types                  Show which types each file has.
  --files-from=FILE             Read the list of files to search from FILE.
  -x                            Read the list of files to search from STDIN.

File inclusion/exclusion:
  --[no]ignore-dir=name         Add/remove directory from list of ignored dirs
  --[no]ignore-directory=name   Synonym for ignore-dir
  --ignore-file=FILTER:ARGS     Add filter for ignoring files.
  -r, -R, --recurse             Recurse into subdirectories (default: on)
  -n, --no-recurse              No descending into subdirectories
  --[no]follow                  Follow symlinks.  Default is off.

File type inclusion/exclusion:
  -t X, --type=X                Include only X files, where X is a filetype,
                                e.g. python, html, markdown, etc
  -T X, --type=noX              Exclude X files, where X is a filetype.
  -k, --known-types             Include only files of types that ack recognizes.
  --help-types                  Display all known types, and how they're defined.

File type specification:
  --type-set=TYPE:FILTER:ARGS   Files with the given ARGS applied to the given
                                FILTER are recognized as being of type TYPE.
                                This replaces an existing definition for TYPE.
  --type-add=TYPE:FILTER:ARGS   Files with the given ARGS applied to the given
                                FILTER are recognized as being type TYPE.
  --type-del=TYPE               Removes all filters associated with TYPE.

Miscellaneous:
  --version                     Display version & copyright
  --[no]env                     Ignore environment variables and global ackrc
                                files.  --env is legal but redundant.
  --ackrc=filename              Specify an ackrc file to use
  --ignore-ack-defaults         Ignore default definitions included with ack.
  --create-ackrc                Outputs a default ackrc for your customization
                                to standard output.
  --dump                        Dump information on which options are loaded
                                and where they're defined.
  --[no]filter                  Force ack to treat standard input as a pipe
                                (--filter) or tty (--nofilter)
  --help                        This help
  --man                         Print the manual.
  --help-types                  Display all known types, and how they're defined.
  --help-colors                 Show a list of possible color combinations.
  --help-rgb-colors             Show a list of advanced RGB colors.
  --thpppt                      Bill the Cat
  --bar                         The warning admiral
  --cathy                       Chocolate! Chocolate! Chocolate!

Filter specifications:
    If FILTER is "ext", ARGS is a list of extensions checked against the
        file's extension.
    If FILTER is "is", ARGS must match the file's name exactly.
    If FILTER is "match", ARGS is matched as a case-insensitive regex
        against the filename.
    If FILTER is "firstlinematch", ARGS is matched as a regex the first
        line of the file's contents.

Exit status is 0 if match, 1 if no match.

ack's home page is at https://beyondgrep.com/

The full ack manual is available by running "ack --man".

This is version $App::Ack::VERSION of ack.  Run "ack --version" for full version info.
END_OF_HELP

    return;
 }


=head2 show_help_types()

Display the filetypes help subpage.

=cut

sub show_help_types {
    App::Ack::print( <<'END_OF_HELP' );
Usage: ack [OPTION]... PATTERN [FILES OR DIRECTORIES]

The following is the list of filetypes supported by ack.  You can specify a
filetype to include with -t TYPE or --type=TYPE.  You can exclude a
filetype with -T TYPE or --type=noTYPE.

Note that some files may appear in multiple types.  For example, a file
called Rakefile is both Ruby (--type=ruby) and Rakefile (--type=rakefile).

END_OF_HELP

    my @types = keys %App::Ack::mappings;
    my $maxlen = 0;
    for ( @types ) {
        $maxlen = length if $maxlen < length;
    }
    for my $type ( sort @types ) {
        next if $type =~ /^-/; # Stuff to not show
        my $ext_list = $mappings{$type};

        if ( ref $ext_list ) {
            $ext_list = join( '; ', map { $_->to_string } @{$ext_list} );
        }
        App::Ack::print( sprintf( "    %-*.*s %s\n", $maxlen, $maxlen, $type, $ext_list ) );
    }

    return;
}


=head2 show_help_colors()

Display the colors help subpage.

=cut

sub show_help_colors {
    App::Ack::print( <<'END_OF_HELP' );
ack allows customization of the colors it uses when presenting matches
onscreen.  See the "ACK COLORS" section of the ack manual (ack --man).

Here is a chart of how various color combinations appear: Each of the eight
foreground colors, on each of the eight background colors or no background
color, with and without the bold modifier.

Run ack --help-rgb-colors for a chart of the RGB colors.

END_OF_HELP

    _show_color_grid();

    return;
}


=head2 show_help_rgb()

Display the RGB help subpage.

=cut

sub show_help_rgb {
    App::Ack::print( <<'END_OF_HELP' );
ack allows customization of the colors it uses when presenting matches
onscreen.  See the "ACK COLORS" section of the ack manual (ack --man).

Colors may be specified as "rgbNNN" where "NNN" is a triplet of digits
from 0 to 5 specifying the intensity of red, green and blue, respectively.

Here is a grid of the 216 possible values for NNN.

END_OF_HELP

    _show_rgb_grid();

    App::Ack::say( 'Here are the 216 possible colors with the "reverse" modifier applied.', "\n" );

    _show_rgb_grid( 'reverse' );

    return;
}


sub _show_color_grid {
    my $cell_width = 7;

    my @fg_colors = qw( black red green yellow blue magenta cyan white );
    my @bg_colors = map { "on_$_" } @fg_colors;

    App::Ack::say(
        _color_cell( '' ),
        map { _color_cell( $_ ) } @fg_colors
    );

    App::Ack::say(
        _color_cell( '' ),
        map { _color_cell( '-' x $cell_width ) } @fg_colors
    );

    for my $bg ( '', @bg_colors ) {
        App::Ack::say(
            _color_cell( '' ),
            ( map { _color_cell( $_, "$_ $bg" ) } @fg_colors ),
            $bg
        );

        App::Ack::say(
            _color_cell( 'bold' ),
            ( map { _color_cell( $_, "bold $_ $bg" ) } @fg_colors ),
            $bg
        );
        App::Ack::say();
    }

    return;
}


sub _color_cell {
    my $text  = shift;
    my $color = shift;

    my $cell_width = 7;
    $text = sprintf( '%-*s', $cell_width, $text );

    return ($color ? Term::ANSIColor::colored( $text, $color ) : $text) . ' ';
}


sub _show_rgb_grid {
    my $modifier = shift // '';

    my $grid = <<'HERE';
544 544 544 544 544 554 554 554 554 554 454 454 454 454 454 455 455 455 455 455 445 445 445 445 445 545 545 545 545 545
533 533 533 543 543 553 553 553 453 453 353 353 353 354 354 355 355 355 345 345 335 335 335 435 435 535 535 535 534 534
511 521 531 531 541 551 451 451 351 251 151 152 152 153 154 155 145 145 135 125 115 215 215 315 415 515 514 514 513 512
500 510 520 530 540 550 450 350 250 150 050 051 052 053 054 055 045 035 025 015 005 105 205 305 405 505 504 503 502 501
400 410 410 420 430 440 340 340 240 140 040 041 041 042 043 044 034 034 024 014 004 104 104 204 304 404 403 403 402 401
300 300 310 320 320 330 330 230 130 130 030 030 031 032 032 033 033 023 013 013 003 003 103 203 203 303 303 302 301 301
200 200 200 210 210 220 220 220 120 120 020 020 020 021 021 022 022 022 012 012 002 002 002 102 102 202 202 202 201 201
100 100 100 100 100 110 110 110 110 110 010 010 010 010 010 011 011 011 011 011 001 001 001 001 001 101 101 101 101 101

522 522 532 542 542 552 552 452 352 352 252 252 253 254 254 255 255 245 235 235 225 225 325 425 425 525 525 524 523 523

411 411 421 431 431 441 441 341 241 241 141 141 142 143 143 144 144 134 124 124 114 114 214 314 314 414 414 413 412 412

422 422 432 432 432 442 442 442 342 342 242 242 242 243 243 244 244 244 234 234 224 224 224 324 324 424 424 424 423 423

311 311 311 321 321 331 331 331 231 231 131 131 131 132 132 133 133 133 123 123 113 113 113 213 213 313 313 313 312 312

433 433 433 433 433 443 443 443 443 443 343 343 343 343 343 344 344 344 344 344 334 334 334 334 334 434 434 434 434 434
211 211 211 211 211 221 221 221 221 221 121 121 121 121 121 122 122 122 122 122 112 112 112 112 112 212 212 212 212 212

322 322 322 322 322 332 332 332 332 332 232 232 232 232 232 233 233 233 233 233 223 223 223 223 223 323 323 323 323 323

555 555 555 555 555 555 555 555 555 555 555 555 555 555 555 555 555 555 555 555 555 555 555 555 555 555 555 555 555 555
444 444 444 444 444 444 444 444 444 444 444 444 444 444 444 444 444 444 444 444 444 444 444 444 444 444 444 444 444 444
333 333 333 333 333 333 333 333 333 333 333 333 333 333 333 333 333 333 333 333 333 333 333 333 333 333 333 333 333 333
222 222 222 222 222 222 222 222 222 222 222 222 222 222 222 222 222 222 222 222 222 222 222 222 222 222 222 222 222 222
111 111 111 111 111 111 111 111 111 111 111 111 111 111 111 111 111 111 111 111 111 111 111 111 111 111 111 111 111 111
000 000 000 000 000 000 000 000 000 000 000 000 000 000 000 000 000 000 000 000 000 000 000 000 000 000 000 000 000 000
HERE

    $grid =~ s/(\d\d\d)/Term::ANSIColor::colored( "$1", "$modifier rgb$1" )/eg;

    App::Ack::say( $grid );

    return;
}


sub show_man {
    require Pod::Usage;
    Pod::Usage::pod2usage({
        -input   => $App::Ack::ORIGINAL_PROGRAM_NAME,
        -verbose => 2,
        -exitval => 0,
    });

    return;
}


=head2 get_version_statement

Returns the version information for ack.

=cut

sub get_version_statement {
    require Config;

    my $copyright = $App::Ack::COPYRIGHT;
    my $this_perl = $Config::Config{perlpath};
    if ($^O ne 'VMS') {
        my $ext = $Config::Config{_exe};
        $this_perl .= $ext unless $this_perl =~ m/$ext$/i;
    }
    my $perl_ver = sprintf( 'v%vd', $^V );

    my $build_type = $App::Ack::STANDALONE ? 'standalone version' : 'standard build';

    return <<"END_OF_VERSION";
ack $App::Ack::VERSION ($build_type)
Running under Perl $perl_ver at $this_perl

$copyright

This program is free software.  You may modify or distribute it
under the terms of the Artistic License v2.0.
END_OF_VERSION
}


sub print            { print {$fh} @_; return; }
sub say              { print {$fh} @_, $ors; return; }
sub print_blank_line { print {$fh} "\n"; return; }

sub set_up_pager {
    my $command = shift;

    return if App::Ack::output_to_pipe();

    my $pager;
    if ( not open( $pager, '|-', $command ) ) {
        App::Ack::die( qq{Unable to pipe to pager "$command": $!} );
    }
    $fh = $pager;

    return;
}

=head2 output_to_pipe()

Returns true if ack's input is coming from a pipe.

=cut

sub output_to_pipe {
    return $output_to_pipe;
}

=head2 exit_from_ack( $nmatches )

Exit from the application with the correct exit code.

Returns with 0 if a match was found, otherwise with 1. The number of matches is
handed in as the only argument.

=cut

sub exit_from_ack {
    my $nmatches = shift;

    my $rc = $nmatches ? 0 : 1;
    exit $rc;
}

=head2 show_types( $file )

Shows the filetypes associated with a given file.

=cut

sub show_types {
    my $file = shift;

    my @types = filetypes( $file );
    my $arrow = @types ? ' => ' : ' =>';
    App::Ack::say( $file->name, $arrow, join( ',', @types ) );

    return;
}


sub filetypes {
    my ( $file ) = @_;

    my @matches;

    foreach my $k (keys %App::Ack::mappings) {
        my $filters = $App::Ack::mappings{$k};

        foreach my $filter (@{$filters}) {
            # Clone the file.
            my $clone = $file->clone;
            if ( $filter->filter($clone) ) {
                push @matches, $k;
                last;
            }
        }
    }

    # https://metacpan.org/pod/distribution/Perl-Critic/lib/Perl/Critic/Policy/Subroutines/ProhibitReturnSort.pm
    @matches = sort @matches;
    return @matches;
}


sub is_lowercase {
    my $pat = shift;

    # The simplest case.
    return 1 if lc($pat) eq $pat;

    # If we have capitals, then go clean up any metacharacters that might have capitals.

    # Get rid of any literal backslashes first to avoid confusion.
    $pat =~ s/\\\\//g;

    my $metacharacter = qr{
        |\\A                # Beginning of string
        |\\B                # Not word boundary
        |\\c[a-zA-Z]        # Control characters
        |\\D                # Non-digit character
        |\\G                # End-of-match position of prior match
        |\\H                # Not horizontal whitespace
        |\\K                # Keep to the left
        |\\N(\{.+?\})?      # Anything but \n, OR Unicode sequence
        |\\[pP]\{.+?\}      # Named property and negation
        |\\[pP][A-Z]        # Named property and negation, single-character shorthand
        |\\R                # Linebreak
        |\\S                # Non-space character
        |\\V                # Not vertical whitespace
        |\\W                # Non-word character
        |\\X                # ???
        |\\x[0-9A-Fa-f]{2}  # Hex sequence
        |\\Z                # End of string
    }x;
    $pat =~ s/$metacharacter//g;

    my $name = qr/[_A-Za-z][_A-Za-z0-9]*?/;
    # Eliminate named captures.
    $pat =~ s/\(\?'$name'//g;
    $pat =~ s/\(\?<$name>//g;

    # Eliminate named backreferences.
    $pat =~ s/\\k'$name'//g;
    $pat =~ s/\\k<$name>//g;
    $pat =~ s/\\k\{$name\}//g;

    # Now with those metacharacters and named things removed, now see if it's lowercase.
    return 1 if lc($pat) eq $pat;

    return 0;
}


# Returns a regex object based on a string and command-line options.
# Dies when the regex $str is undefined (i.e. not given on command line).

sub build_regex {
    my $str = shift;
    my $opt = shift;

    # Check for lowercaseness before we do any modifications.
    my $regex_is_lc = App::Ack::is_lowercase( $str );

    if ( $opt->{Q} ) {
        $str = quotemeta( $str );
    }
    else {
        # Compile the regex to see if it dies or throws warnings.
        local $SIG{__WARN__} = sub { CORE::die @_ };  # Anything that warns becomes a die.
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


sub build_all_regexes {
    my $opt_regex = shift;
    my $opt = shift;

    my $re_match;
    my $re_not;
    my $re_hilite;
    my $re_scan;

    my @parts;

    # AND: alpha AND beta
    if ( @parts = @{$opt->{and}} ) {
        my @match_parts;
        my @hilite_parts;

        for my $part ( @parts ) {
            my ($match, undef) = build_regex( $part, $opt );
            push @match_parts, "(?=.*$match)";
            push @hilite_parts, $match;
        }

        my ($match, $scan) = build_regex( $opt_regex, $opt );
        push @match_parts, ".*$match";
        push @hilite_parts, $match;

        $re_match  = join( '', @match_parts );
        $re_hilite = join( '|', @hilite_parts );
        $re_scan   = $scan;
    }
    # OR: alpha OR beta
    elsif ( @parts = @{$opt->{or}} ) {
        my @match_parts;
        my @scan_parts;

        for my $part ( $opt_regex, @parts ) {
            my ($match, $scan) = build_regex( $part, $opt );
            push @match_parts, $match;
            push @scan_parts, $scan;
        }

        $re_match  = join( '|', @match_parts );
        $re_hilite = $re_match;
        $re_scan   = join( '|', @scan_parts );
    }
    else {
        ($re_match, $re_scan) = build_regex( $opt_regex, $opt );
        $re_hilite = $re_match;
    }

    # The --not does not affect the main regex. It is checked separately.
    # NOT: alpha NOT beta
    if ( @parts = @{$opt->{not}} ) {
        my @not_parts;
        for my $part ( @parts ) {
            (my $re, undef) = build_regex( $part, $opt );
            push @not_parts, $re;
        }
        $re_not = join( '|', @not_parts );
    }

    return ($re_match, $re_not, $re_hilite, $re_scan);
}


1; # End of App::Ack
