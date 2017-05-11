package App::Ack::Docs::Cookbook;

=head1 COOKBOOK

Here are examples of how to effectively use ack.

=head2 Find "goats" in every file that also contains "cows"

Use command substitution to pass a list of cow files to ack:

    ack goats $(ack -l cows)

Or you can use the program F<xargs> to feed the filenames to the
goat search.

    ack -l cows | xargs ack goats

Or you can use ack's C<-x> option to do the same thing without
having to get F<xargs> involved.

    ack -l cows | ack -x goats

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

=head2 Examples of F<--output>

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

    ack3.pl "\w*e\w*" quick.txt --output="$`_$&_$'"
    _The_ quick brown fox jumps over the lazy dog
    The quick brown fox jumps _over_ the lazy dog
    The quick brown fox jumps over _the_ lazy dog

This shows how to pick out particular parts of a match using ( ) within regular expression.

    ack '=head(\d+)\s+(.*)' --output=' $1 : $2'
    input file contains "=head1 NAME"
    output  "1 : NAME"

=cut;

1;
