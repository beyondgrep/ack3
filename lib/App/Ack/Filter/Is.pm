package App::Ack::Filter::Is;

=head1 NAME

App::Ack::Filter::Is

=head1 DESCRIPTION

Filters based on exact filename match.

=cut

use strict;
use warnings;
use parent 'App::Ack::Filter';

use File::Spec 3.00 ();
use App::Ack::Filter::IsGroup ();

sub new {
    my ( $class, $filename ) = @_;

    return bless {
        filename => $filename,
        groupname => 'IsGroup',
    }, $class;
}

sub create_group {
    return App::Ack::Filter::IsGroup->new();
}

sub filter {
    my ( $self, $file ) = @_;

    return (File::Spec->splitpath($file->name))[2] eq $self->{filename};
}

sub inspect {
    my ( $self ) = @_;

    return ref($self) . ' - ' . $self->{filename};
}

sub to_string {
    my ( $self ) = @_;

    return $self->{filename};
}

BEGIN {
    App::Ack::Filter->register_filter(is => __PACKAGE__);
}

1;
