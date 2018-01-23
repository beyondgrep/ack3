package App::Ack::Filter::Match;

use strict;
use warnings;
use parent 'App::Ack::Filter';

use App::Ack::Filter::MatchGroup ();

=head1 NAME

App::Ack::Filter::Match

=head1 DESCRIPTION

Implements filtering files by their filename (regular expression).

=cut

sub new {
    my ( $class, $re ) = @_;

    $re =~ s{^/|/$}{}g; # XXX validate?
    $re = qr/$re/i;

    return bless {
        regex => $re,
        groupname => 'MatchGroup',
    }, $class;
}

sub create_group {
    return App::Ack::Filter::MatchGroup->new;
}

sub filter {
    my ( $self, $file ) = @_;

    return $file->basename =~ /$self->{regex}/;
}

sub inspect {
    my ( $self ) = @_;

    return ref($self) . ' - ' . $self->{regex};
}

sub to_string {
    my ( $self ) = @_;

    return "Filename matches $self->{regex}";
}

BEGIN {
    App::Ack::Filter->register_filter(match => __PACKAGE__);
}

1;
