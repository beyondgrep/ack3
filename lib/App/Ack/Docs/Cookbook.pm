package App::Ack::Docs::Cookbook;



=head1 COOKBOOK

Here are examples of how to effectively use ack.

Note: on Windows CMD prompt, the quoting may need to switch C<"> for C<'> and/or vice-versa.




=head1 COMPOUND QUERIES

Some compound queries can be done in a single RE pattern but most will require a pipeline command.

=head2 Find "goat(s)" or "cow(s)" or both

    ack '(goats?|cows?)'

=head2 Find "goats" in every file that also contains "cows"

Use command substitution to pass a list of cow files to ack:

    ack goats $(ack -l cows)

Or you can use the program F<xargs> to feed the filenames to the
goat search.

    ack -l cows | xargs ack goats

Or you can use ack's C<-x> option to do the same thing without
having to get F<xargs> involved.

    ack -l cows | ack -x goats


=head2 Find goats in files that do not contain cows

    ack -L cows | ack -x -l goats

=head2 Find "goats" in every farmish file

One of the usual FAQ is how do I use C<< -f pattern1 >> for files
and C< pattern2 > within the files in one command?

The answer is don't, use two C<ack>s, either via a Pipe, or nest them.

   ack -ig 'farm|(?:ei)+o$' | ack -x goats

   ack goats $(ack -ig 'farm|(?:ei)+o$' )

=head2 Find "goats" and "cows" in the same line, either order, as words

Following the  compound is a pipeline trope,
if we assume filenames don't also have goats -

   ack  cows | ack goats

This obviously could scale to N terms, at the cost of N processes.

But for just two, we can easily do it in on go, too:

    ack '\bgoats\b.*\bcows\b|\bcows\b.*\bgoats\b'

C<|> says "OR".

C<< \b >> says word boundary here, letters one side and space or punctuation on the other,
so half of a Whole-words limitation.

C<.*> says anything or nothing, but wrapped in C<\b.*\b> with words on outsides,
will have space or punctuation first and last, unless nothing -- and nothing isn't
allowed, need at least a single space or comma, not C<goatscows>.

=head2 Search for all the files that mention Sys::Hostname but don't match hostname.

    ack -l Sys::Hostname | ack -x -L -I hostname

(We added C<-I> (the reverse of C<-i> or C<< --ignore-case >>)
because we have C<< --smart-case >> on in our C<.ackrc>.
The first C<ack> doesn't need it because smart-case smartly goes case-sensitive when pattern has some UpperCase.
We could have typed C<< --no-smart-case >> but that's too much to type,
so C<-I> on commandline, longform in scripts!)


=head2 Find all goat(s) in files without cows

 Search all the files that don't have cow(s) and show their goat(s).

    ack -L 'cows?' | ack -x -w 'goats?'

=head2  Search and highlight a specific pattern 'goat' but exclude lines that match also another pattern 'cow'.

    ack '^(?!.*?cow).*?\Kgoat'

The C<\K> is called KEEP; aside from preventing backtracking, it resets the C<$` $&> boundary, the start of match.
C<(?!.*cow)> is a negative lookahead.
C<.*?> is non-greedy so the search is left to right.




=head1 USING ACK EFFECTIVELY

=head2 Use the F<.ackrc> file.

The F<.ackrc> is the place to put all your options you use most of
the time but don't want to remember.  Put all your C<--type-add>
and C<--type-set> definitions in it.  If you like C<--smart-case> and
C<--sort-files>, set them there, too.


=head2 Use F<-f> for working with big codesets

Ack does more than search files.  C<ack -f --perl> will create a
list of all the Perl files in a tree, ideal for sending into F<xargs>.
For example:

    # Change all "this" to "that" in all Perl files in a tree.
    ack -f --perl | xargs perl -p -i -e's/this/that/g'

or if you prefer:

    perl -p -i -e's/this/that/g' $(ack -f --perl)

=head2 Use F<-Q> when in doubt about metacharacters

If you're searching for something with a regular expression
metacharacter, most often a period in a filename or IP address, add
the -Q to avoid false positives without all the backslashing.  See
the following example for more...

=head2 Use ack to watch log files

Here's one I used the other day to find trouble spots for a website
visitor.  The user had a problem loading F<troublesome.gif>, so I
took the access log and scanned it with ack twice.

    ack -Q aa.bb.cc.dd /path/to/access.log | ack -Q -B5 troublesome.gif

The first ack finds only the lines in the Apache log for the given
IP.  The second finds the match on my troublesome GIF, and shows
the previous five lines from the log in each case.

=head2 Use ack instead of find

    ack -f --html --print0 | xargs -0 wc -l

(You may omit the C<< --print0 >> and C<-0> if none of your files or directories contain a space in the name.)

=head2 Searching for a method call

    ack -- '->method'

or

    ack '[-]>method'

(Optionally followed by "word boundary" marker C<\b>
as in  C<< [-]>method\b >> to not find C<< ->methodically >> .)

=head2 Use C<-w> only for words

C<ack -w pattern> will restrict the match to C<pattern> as a word, surrounded by whitespace or punctuation
(and both ends of lines count as whitespace).
(Word means alphabetic or '_' in this context.
If your OS tells Perl that certain accented characters are alphabetic for you, they may be included, try it!)

If your desired pattern begins with one word and ends with another, C<-w> is still safe.

If your desired pattern starts or ends (or both) with punctuation, using C<-w> may be erroneous
(and will likely warn so).
In which case, SWYM: Say What You Mean.
If you mean the start of your pattern with punctuation should be
at the beginning of line B<OR> preceded by a word OR by a space (or tab etc), before the needed punctuation,
SWIM as C<(?:^|\b|\s)#+\s+(.*)>
which will find and capture a comment.
(Try it plain, with C<-o>, and with C<--output='$1'>, which has its own section below)

So don't look for C<ack -w '$identifier'>, it won't match C<+$identifier> or C<func($identifier)> and won't even find it in column 1; do instead

   ack '(?:^|\s|\b)\$identifier\b'

   ack '(?x)(?: ^ | \b | (?<=  \W | \s  )) [#]  DEBUG (?= \b | \s | $) '

SWYMingly finds C<< #DEBUG >> if at beginning of line, after a word break, a non-word char, or a space char,
and followed by a word-break, or space, or end-of-line. 
This uses look-behind and look-ahead so that only B<#DEBUG> is highlighted (or saved to C<$&>),
and also C<(?x)> the B<extended> syntax, in which whitespace is only match if explicitly C<\s> or C<\0x20> or C<[ ]>,
the blanks are for readability.

(This is over-specified, since C<G> followed by space would be C<\b>, and C<\s> is C<\W>, but if you're not sure, it's OK to over-specify ! )


=head2 See all the C<.vim> files in your hidden C<~/.vim> directory, except in the C<bundle/> directory.

    ack -f --vim ~/.vim --ignore-dir=bundle

=head2 Finds all the ruby files that match /tax/.

   ack -g tax --ruby

Open all the files that have taxes in them.

   vim $(ack -l taxes)

=head2 Find all the Perl test files and test them

Use C<ack>'s file-type inference to find things of C<--type=perltest>
and feed them to C<xargs> which runs them all against the C<prove> command.

     ack -f --perltest | xargs prove

=head2 Find places where two methods with the same name are being called on the same line.

    ack -- '->(\w+).*->\1\b'

The C<< (\w+) >> captures a method name (introduced by C<< -> >> ),
which is then sought a second time as C<\1>, a backreference.
The backreference needs a trailing C<\b> so C<< ->method ... ->methodically >> does not match.
The C<< (\w+) >> needs neither left nor right side C<\b> because the C<+> modifier is greedy, will take all the word chars available.

=head2 Find all the places in code there's a call like C<< sort { lc $a cmp lc $b } >>.

This is heuristic; it gets false positive, but it's pretty useful.

    ack '\bsort\b.+(\w+).+\bcmp\b.+\b(\1)\b'

(The word and backreference are matching the canonicalizing use of C<lc> to lowercase both comparands.)

=head2 Show a range of lines in a file

     ack --lines=830-850 filename

And use -H to show what line numbers are.

=head2 Find modules that are importing but not actually using C<Test::Warn>

    ack -L 'warnings?_' $(ack -l Test::Warn)


=head2 Search only recently changed or 'dirty' files

Most version control systems provide a query to list files changed since checkout, often referred to as 'dirty' files. E.g.,

   alias dirty="git diff --name-only"

   dirty | ack -x pattern

=head1 EXAMPLES OF C<< --output >>

Following variables are useful in the expansion string:

=over 4

=item C<$&>

The whole string matched by PATTERN.

=item C<$1>, C<$2>, ...

The contents of the 1st, 2nd ... bracketed group in PATTERN.

=item C<$`>

The string before the match.

=item C<$'>

The string after the match.

=back

For more details and other variables see
L<http://perldoc.perl.org/perlvar.html#Variables-related-to-regular-expressions|perlvar>.

This example shows how to add text around a particular pattern
(in this case adding _ around word with "e")

    ack3 "\w*e\w*" quick.txt --output="$`_$&_$'"
    _The_ quick brown fox jumps over the lazy dog
    The quick brown fox jumps _over_ the lazy dog
    The quick brown fox jumps over _the_ lazy dog

This shows how to pick out particular parts of a match using ( ) within regular expression.

    ack '=head(\d+)\s+(.*)' --output=' $1 : $2'
    input file contains "=head1 NAME"
    output  "1 : NAME"

=head2 Find all the headers used in your C programs and dedupe them

    ack '#include\s+<(.+)>' --cc --output='$1' | sort -u

=head2 Find the most-used modules in your codebase.


    ack '^use ([\w+:]+)' --output='$1' -h --nogroup | sort | uniq -c  | sort -n

=head2 Find all the subroutines in Perl tests and then give a count of many of each there are

     ack '^sub (\w+)' --perltest --output='$1' -h --nogroup | sort | uniq -c  | sort -n


=head2 In COBOL source code, match only lines with blank in column 7, ignore

    ack '^.{6}[ ].*?\Kpattern'
    ack '(?x) ^ .{6} [ ] .*? \K pattern'  # same but readable

    
Again using the C<\K> Keep to reset start of matching.
    
(Legacy COBOL put C<'*'> in Col 7 for comments, back in punch-card days. 
FORTRAN in the day similarly used 'C' or '*' in Col 1. 
Early FORTRAN wrapped lines with C<&> in Col 73 and in Col 6 of next line.) 


(Hat-tip for Question to Pierre)
   


=head1 VERY ELEGANT ACK

=head2 Open list of matching files in Vim, searching for your search term

     $ ack my_search_term
     <results>
     $ vim $(!! -l) +/!$

=over 4

=item C<!!> expands to the previous command - C<ack my_search_term> in the example

=item C<$(...)> expands to the output of the command in the parens, so the output of C<ack my_search_term -l> in the example

=item C<<  +/<term> >> tells Vim to start searching for C<< <term> >> once it opens

=item C<< !$ >> expands to the last argument of the previous command - my_search_term in the example

=back

Small caveat: Vim patterns and Perl regexes have some overlap, but they are different, so this doesn't work
so well when you have a more complex regex as your search term.
Vim command C<< :help perl-patterns >> will report what Vim thinks the differences are.

=head2 Extending ack your way

A user who really wants the working directory reported makes a C<bash function> (which will look like an alias) to make it so. Hat tip to B<teika-kazura> !

    function ack(){
        local ackLogDir=/tmp/mylogs/Ack
        mkdir -p "$ackLogDir"
        chmod 777 "$ackLogDir" &> /dev/null
        if [[ $# == 0 ]]; then
            find "$ackLogDir" -type f | xargs ls -t |xargs less
            return
        fi
        local f="$( mktemp --tmpdir=$ackLogDir )"
        echo "# Pwd: `pwd`" > $f
        echo "# ack $@" >> $f
        command ack "$@" >> "$f" 2>&1
        less $f
    }

(I can't really recommend C<chmod 777> , you're better off with per-user temp sub-dirs for security safety,
whether under C<$HOME> or under C</tmp/$USER>.)

=head2 Find log lines with 4 nulls and sort by IP address


via L<@clmagic|https://twitter.com/clmagic> "Command Line Magic" twitter bot -

    egrep -- "\t-\t-\t-\t-\t" entries.txt |sort -k3V
    # Get the entries with 4+ null fields and sort the entries by IPv4 (-V) in the 3rd column.

(Well actually (tm) it's 4+ B<adjacent> null tab-separated fields, null represented as dashes.)

C<ack> will happily do likewise, no changes:


    ack -- "\t-\t-\t-\t-\t" entries.txt |sort -k3V

The difference with C<ack> being, you can use the larger C<perldoc perlre> pattern language,
larger than even C<egrep>'s, to better SWYM DRY (Don't Repeat Yourself):

    ack -- "(?x: \t  (?: - \t ){4} )" entries.txt |sort -k3V

to explicitly count (C<< (?:  ){4} >>) the tab-separated dashes.
The C<< (?x: ) >>  says spaces don't count, are used for readability.
If 'null' was optional spaces between the tabs not a single dash,
we'd use a character class of just space C<< [ ] >>:

    ack -- "(?x: \t  (?: [ ]* \t ){4} )" entries.txt |sort -k3V

(We could use a C<\ > escaped space, but that's hard to read, especially hard to tell if wrong.
Is that one space or two there?)

(L<regex cheatsheat comparing ack's perlRe with (e)grep, sed, ...|https://remram44.github.io/regex-cheatsheet/regex.html>


=head2 Summarize the file-types in your project

    $ ack --noenv --show-type -f | perl -MData::Dumper -naE'++$n{$F[-1]}; END {print Dumper \%n}'
    $VAR1 = {
          'xml' => 32,
          'sql' => 2,
          'shell' => 4,
          'php,shell' => 8,
          'yaml' => 1809,
          'php' => 7122,
          'css' => 360,
          'markdown' => 7,
          'html' => 7,
          '=>' => 1180,
          'json' => 69,
          'js' => 582
        };

=head2 Fowler's Folly

In old C<ack2>, Mark Fowler demonstrated the reason we banned C<--output>
from the new Project scoped C<.ackrc> in the PerlAdvent calendar i
L<http://www.perladvent.org/2014/2014-12-21.html>,
to annotate the URLs found in a file with their download weights:

    ack2 --output='$&: @{[ eval "use LWP::Simple; 1" && length LWP::Simple::get($&) ]} bytes' \
           'https?://\S+' list.txt
    http://google.com/: 19529 bytes
    http://metacpan.org/: 7560 bytes
    http://www.perladvent.org/: 5562 bytes

C<ack3> restricts C<--output> to using only the safe and sensible variables documented,
and emphatically not code execution via array interpolation.

But you can sill do this, it just requires a pipe --

    ack -o 'https?://\S+' DEVELOPERS.md  \
    |  perl -nl -MLWP::Simple \
                -E 'say "$_ :  @{[ length LWP::Simple::get($_) ]}  bytes";'
    https://github.com/petdance/beyondgrep :  50784  bytes
    https://github.com/petdance/ack3/issues :  111627  bytes

=head2 KWIC: KeyWord in Context index

A KeyWord In Context (KWIC) index was more useful in the days of offline computing and line-printer reports but is still sometimes relevant to see the matches not (just) highlighted but lined up for easy scanning.

The tradidional distinction between KWIC and KWOC is whether the Keyword is at start of line with it's left context wrapped (KWOC= Out of), 
or tab separated in the middle. KWIC works best with two word-processor fixed tabsets, not with 8-char tabs, alas.

            ack  --output '$&^I$'"'"'^I|| $`' pattern files | sort     # KWOC
            ack  --output '$&^I$\'^I|| $`'    pattern files | sort     # KWOC

            ack  --output '$`^I$&^I$'"'" pattern files | sort -df -t^I -k F2,F2 # pseudo KWIC 
            ack  --output '$`^I$&^I$\''  pattern files | sort -df -t^I -k F2,F2 # pseudo KWIC 

(On the KWOC, the C<||> shows where right and left margin are wrapped.)
(To make the KWIC output look right, load into OpenOffice or Word to spread the tab stops !)

 
=head2 TBD lookahead and lookbehind

=cut;

1;
