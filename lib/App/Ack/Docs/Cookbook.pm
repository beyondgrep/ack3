package App::Ack::Docs::Cookbook;

=pod

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

=cut

1;
