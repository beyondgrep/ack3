package App::Ack::Docs::FAQ;

=pod

=head1 FAQ

This is the Frequently Asked Questions list for ack.  You can also see the
manual in the Perl module App::Ack::Docs::Manual, or running F<ack --man>.

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

Yes!  Please see L</"Defining your own types">.  If you think
that F<ack> should recognize a type by default, please see
L</"ENHANCEMENTS">.

=head2 There's already a program/package called ack.

Yes, I know.

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

We try to remain as close to grep's behavior as possible, so when in doubt,
see what grep does!  If there's a mismatch in functionality there, please
bring it up on the ack-users mailing list.

=cut

1;
