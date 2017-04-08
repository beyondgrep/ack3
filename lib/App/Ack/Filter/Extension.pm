package App::Ack::Filter::Extension;

=head1 NAME

App::Ack::Filter::Extension

=head1 DESCRIPTION

Implements filters based on extensions.

=cut

use strict;
use warnings;
use parent 'App::Ack::Filter';

use App::Ack::Filter ();
use App::Ack::Filter::ExtensionGroup ();

sub new {
    my ( $class, @extensions ) = @_;

    my $exts = join('|', map { "\Q$_\E"} @extensions);
    my $re   = qr/[.](?:$exts)$/i;

    return bless {
        extensions => \@extensions,
        regex      => $re,
        groupname  => 'ExtensionGroup',
    }, $class;
}

sub create_group {
    return App::Ack::Filter::ExtensionGroup->new();
}

sub filter {
    my ( $self, $file ) = @_;

    return $file->name =~ /$self->{regex}/;
}

sub inspect {
    my ( $self ) = @_;

    return ref($self) . ' - ' . $self->{regex};
}

sub to_string {
    my ( $self ) = @_;

    return join( ' ', map { ".$_" } @{$self->{extensions}} );
}

BEGIN {
    App::Ack::Filter->register_filter(ext => __PACKAGE__);
}

1;
