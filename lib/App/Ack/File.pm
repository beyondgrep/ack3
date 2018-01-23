package App::Ack::File;

use warnings;
use strict;

use App::Ack ();
use File::Spec ();

=head1 NAME

App::Ack::File

=head1 DESCRIPTION

Abstracts a file from the filesystem.

=head1 METHODS

=head2 new( $filename )

Opens the file specified by I<$filename> and returns a filehandle and
a flag that says whether it could be binary.

If there's a failure, it throws a warning and returns an empty list.

=cut

sub new {
    my $class    = shift;
    my $filename = shift;

    my $self = bless {
        filename => $filename,
        fh       => undef,
        opened   => 0,
    }, $class;

    if ( $self->{filename} eq '-' ) {
        $self->{fh}     = *STDIN;
        $self->{opened} = 1;
    }

    return $self;
}


=head2 $file->name()

Returns the name of the file.

=cut

sub name {
    return $_[0]->{filename};
}


=head2 $file->basename()

Returns the basename (the last component the path)
of the file.

=cut

sub basename {
    my ( $self ) = @_;

    # XXX Definedness? Pre-populate the slot with an undef?
    unless ( exists $self->{basename} ) {
        $self->{basename} = (File::Spec->splitpath($self->name))[2];
    }

    return $self->{basename};
}


=head2 $file->open()

Opens a filehandle for reading this file and returns it, or returns
undef if the operation fails (the error is in C<$!>).  Instead of calling
C<close $fh>, C<$file-E<gt>close> should be called.

=cut

sub open {
    my ( $self ) = @_;

    if ( !$self->{opened} ) {
        if ( open $self->{fh}, '<', $self->{filename} ) {
            $self->{opened} = 1;
        }
        else {
            $self->{fh} = undef;
        }
    }

    return $self->{fh};
}


=head2 $file->reset()

Resets the file back to the beginning.  This is only called if
C<needs_line_scan()> is true, but not always if C<needs_line_scan()>
is true.

=cut

sub reset {
    my $self = shift;

    if ( defined($self->{fh}) ) {
        return unless -f $self->{fh};

        if ( !seek( $self->{fh}, 0, 0 ) && $App::Ack::report_bad_filenames ) {
            App::Ack::warn( "$self->{filename}: $!" );
        }
    }

    return;
}


=head2 $file->close()

Close the file.

=cut

sub close {
    my $self = shift;

    # Return if we haven't opened the file yet.
    if ( !defined($self->{fh}) ) {
        return;
    }

    if ( !close($self->{fh}) && $App::Ack::report_bad_filenames ) {
        App::Ack::warn( $self->name() . ": $!" );
    }

    $self->{opened} = 0;

    return;
}


=head2 $file->clone()

Clones this file.

=cut

sub clone {
    my ( $self ) = @_;

    return __PACKAGE__->new($self->name);
}


=head2 $file->firstliney()

Returns the first line of a file (or first 250 characters, whichever
comes first).

=cut

sub firstliney {
    my ( $self ) = @_;

    if ( !exists $self->{firstliney} ) {
        my $fh = $self->open();
        if ( !$fh ) {
            if ( $App::Ack::report_bad_filenames ) {
                App::Ack::warn( $self->name . ': ' . $! );
            }
            $self->{firstliney} = '';
        }
        else {
            my $buffer;
            my $rc = sysread( $fh, $buffer, 250 );
            if ( $rc ) {
                $buffer =~ s/[\r\n].*//s;
            }
            else {
                if ( !defined($rc) ) {
                    App::Ack::warn( $self->name . ': ' . $! );
                }
                $buffer = '';
            }
            $self->{firstliney} = $buffer;
            $self->reset;
        }
    }

    return $self->{firstliney};
}

1;
