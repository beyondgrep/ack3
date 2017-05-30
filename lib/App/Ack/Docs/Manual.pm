package App::Ack::Docs::Manual;

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
L<http://perldoc.perl.org/perlreref.html|perlreref>.  If you don't know
how to use regular expression but are interested in learning, you may
consult L<http://perldoc.perl.org/perlretut.html|perlretut>.  If you do not
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

=item B<--color-lineno=I<color>>

Sets the color to be used for line numbers.

=item B<--[no]column>

Show the column number of the first match.  This is helpful for
editors that can place your cursor at a given position.

=item B<--cookbook>

Print the ack cookbook, a list of common tricks and recipes for using ack.

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

=item B<--faq>

Print the list of frequently asked questions.

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

=item B<--help>, B<-?>

Print a short help statement.

=item B<--help-types>, B<--help=types>

Print all known types.

=item B<-i>, B<--ignore-case>

Ignore case distinctions in PATTERN.  This option overrides B<--smart-case> and B<-I>.

=item B<-I>

Turns on case distinctions in PATTERN.  This option overrides B<--smart-case> and B<-i>.

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

=item B<--lines=I<NUM>>

Only print line I<NUM> of each file. Multiple lines can be given
with multiple B<--lines> options or as a comma separated list
(B<--lines=3,5,7>). Using a range such as B<--lines=4-7> also works. The
lines are always output in the order found in the file, no matter the
order given on the command line.

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

=item B<-o>

Show only the part of each line matching PATTERN (turns off text
highlighting)

=item B<--output=I<expr>>

Output the evaluation of I<expr> for each line (turns off text
highlighting)
If PATTERN matches more than once then a line is output for each non-overlapping match.
For more information please see the section L</"Examples of F<--output>">.

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

=item B<-Q>, B<--literal>

Quote all metacharacters in PATTERN, it is treated as a literal.

=item B<-r>, B<-R>, B<--recurse>

Recurse into sub-directories. This is the default and just here for
compatibility with grep. You can also use it for turning B<--no-recurse> off.

=item B<-s>

Suppress error messages about nonexistent or unreadable files.  This is taken
from fgrep.

=item B<--[no]smart-case>, B<--no-smart-case>

Ignore case in the search strings if PATTERN contains no uppercase
characters. This is similar to C<smartcase> in the vim text editor.
The options overrides B<-i> and B<-I>.

B<-i> always overrides this option.

=item B<--sort-files>

Sorts the found files lexicographically.  Use this if you want your file
listings to be deterministic between runs of I<ack>.

=item B<--show-types>

Outputs the filetypes that ack associates with each file.

Works with B<-f> and B<-g> options.

=item B<--type=[no]TYPE>

Specify the types of files to include or exclude from a search.
TYPE is a filetype, like I<perl> or I<xml>.  B<--type=perl> can
also be specified as B<--perl>, and B<--type=noperl> can be done
as B<--noperl>.

If a file is of both type "foo" and "bar", specifying --foo and
--nobar will exclude the file, because an exclusion takes precedence
over an inclusion.

Type specifications can be repeated and are ORed together.

See I<ack --help=types> for a list of valid types.

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

=item B<-u>, B<--[no]underline>

Turns on underlining of matches, where "underlining" is not a true
underlining, but printing a line of carets under the match.

    $ ack -u foo
    peanuts.txt
    17: Come kick the football you fool
                      ^^^          ^^^
    623: Price per square foot
                          ^^^

This is useful if you're dumping the results of an ack run into a text
file or printer and don't get any coloring.

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

I<ack --perl foo> searches for foo in all perl files. I<ack --help=types>
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

=head1 ENVIRONMENT VARIABLES

For commonly-used ack options, environment variables can make life
much easier.  These variables are ignored if B<--noenv> is specified
on the command line.

=over 4

=item ACKRC

Specifies the location of the user's F<.ackrc> file.  If this file doesn't
exist, F<ack> looks in the default location.

=item ACK_OPTIONS

This variable specifies default options to be placed in front of
any explicit options on the command line.

=item ACK_COLOR_FILENAME

Specifies the color of the filename when it's printed in B<--group>
mode.  By default, it's "bold green".

The recognized attributes are clear, reset, dark, bold, underline,
underscore, blink, reverse, concealed black, red, green, yellow,
blue, magenta, on_black, on_red, on_green, on_yellow, on_blue,
on_magenta, on_cyan, and on_white.  Case is not significant.
Underline and underscore are equivalent, as are clear and reset.
The color alone sets the foreground color, and on_color sets the
background color.

This option can also be set with B<--color-filename>.

=item ACK_COLOR_MATCH

Specifies the color of the matching text when printed in B<--color>
mode.  By default, it's "black on_yellow".

This option can also be set with B<--color-match>.

See B<ACK_COLOR_FILENAME> for the color specifications.

=item ACK_COLOR_LINENO

Specifies the color of the line number when printed in B<--color>
mode.  By default, it's "bold yellow".

This option can also be set with B<--color-lineno>.

See B<ACK_COLOR_FILENAME> for the color specifications.

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

=head1 AVAILABLE COLORS

F<ack> uses the colors available in Perl's L<Term::ANSIColor> module, which
provides the following listed values. Note that case does not matter when using
these values.

=head2 Foreground colors

    black  red  green  yellow  blue  magenta  cyan  white

    bright_black  bright_red      bright_green  bright_yellow
    bright_blue   bright_magenta  bright_cyan   bright_white

=head2 Background colors

    on_black  on_red      on_green  on_yellow
    on_blue   on_magenta  on_cyan   on_white

    on_bright_black  on_bright_red      on_bright_green  on_bright_yellow
    on_bright_blue   on_bright_magenta  on_bright_cyan   on_bright_white

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

=item * ACK_OPTIONS

Options are then loaded from the environment variable C<ACK_OPTIONS>.  This can
be omitted using C<--noenv>.

=item * Command line

Options are then loaded from the command line.

=back

=head1 BUGS & ENHANCEMENTS

ack is based at GitHub at L<https://github.com/petdance/ack3>

Please report any bugs or feature requests to the issues list at
Github: L<https://github.com/petdance/ack3/issues>.

Please include the operating system that you're using; the output of
the command C<ack --version>; and any customizations in your F<.ackrc>
you may have.

To suggest enhancements, please submit an issue at
L<https://github.com/petdance/ack3/issues>.  Also read the
F<DEVELOPERS.md> file in the ack code repository.

Also, feel free to discuss your issues on the ack mailing
list at L<https://groups.google.com/group/ack-users>.

=head1 SUPPORT

Support for and information about F<ack> can be found at:

=over 4

=item * The ack homepage

L<https://beyondgrep.com/>

=item * Source repository

L<https://github.com/petdance/ack3>

=item * The ack issues list at Github

L<https://github.com/petdance/ack3/issues>

=item * The ack announcements mailing list

L<http://groups.google.com/group/ack-announcement>

=item * The ack users' mailing list

L<http://groups.google.com/group/ack-users>

=item * The ack development mailing list

L<http://groups.google.com/group/ack-users>

=back

=head1 COMMUNITY

There are ack mailing lists and a Slack channel for ack.  See
L<https://beyondgrep.com/community/> for details.

=head1 ACKNOWLEDGEMENTS

How appropriate to have I<ack>nowledgements!

Thanks to everyone who has contributed to ack in any way, including
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

Copyright 2005-2017 Andy Lester.

This program is free software; you can redistribute it and/or modify
it under the terms of the Artistic License v2.0.

See http://www.perlfoundation.org/artistic_license_2_0 or the LICENSE.md
file that comes with the ack distribution.

=cut

1;
