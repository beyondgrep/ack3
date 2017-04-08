package App::Ack::Filter::FirstLineMatch;

=head1 NAME

App::Ack::Filter::FirstLineMatch

=head1 DESCRIPTION

The class that implements filtering files by their first line.

=cut


use strict;
use warnings;
use parent 'App::Ack::Filter';

sub new {
    my ( $class, $re ) = @_;

    $re =~ s{^/|/$}{}g; # XXX validate?
    $re = qr{$re}i;

    return bless {
        regex => $re,
    }, $class;
}

# This test reads the first 250 characters of a file, then just uses the
# first line found in that. This prevents reading something  like an entire
# .min.js file (which might be only one "line" long) into memory.

sub filter {
    my ( $self, $file ) = @_;

    return $file->firstliney =~ /$self->{regex}/;
}

sub inspect {
    my ( $self ) = @_;


    return ref($self) . ' - ' . $self->{regex};
}

sub to_string {
    my ( $self ) = @_;

    (my $re = $self->{regex}) =~ s{\([^:]*:(.*)\)$}{$1};

    return "First line matches /$re/";
}

BEGIN {
    App::Ack::Filter->register_filter(firstlinematch => __PACKAGE__);
}

1;
