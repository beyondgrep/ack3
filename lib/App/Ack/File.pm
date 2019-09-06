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
    }, $class;

    if ( $self->{filename} eq '-' ) {
        $self->{fh}     = *STDIN;
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

    return $self->{basename} //= (File::Spec->splitpath($self->name))[2];
}


=head2 $file->open()

Opens a filehandle for reading this file and returns it, or returns
undef if the operation fails (the error is in C<$!>).  Instead of calling
C<close $fh>, C<$file-E<gt>close> should be called.

=cut

sub open {
    my ( $self ) = @_;

    if ( !$self->{fh} ) {
        if ( open $self->{fh}, '<', $self->{filename} ) {
            # Do nothing.
        }
        else {
            $self->{fh} = undef;
        }
    }

    return $self->{fh};
}


sub may_be_present {
    my $self  = shift;
    my $regex = shift;

    # Tells if the file needs a line-by-line scan.  This is a big
    # optimization because if you can tell from the outset that the pattern
    # is not found in the file at all, then there's no need to do the
    # line-by-line iteration.

    # Slurp up an entire file up to 10M, see if there are any matches
    # in it, and if so, let us know so we can iterate over it directly.

    # The $regex may be undef if it had a "$" in it, and is therefore unsuitable for this heuristic.

    my $may_be_present = 1;
    if ( $regex && $self->open() && -f $self->{fh} ) {
        my $buffer;
        my $size = 10_000_000;
        my $rc = sysread( $self->{fh}, $buffer, $size );
        if ( !defined($rc) ) {
            if ( $App::Ack::report_bad_filenames ) {
                App::Ack::warn( $self->name . ": $!" );
            }
            $may_be_present = 0;
        }
        else {
            # If we read all 10M, then we need to scan the rest.
            # If there are any carriage returns, our results are flaky, so scan the rest.
            if ( ($rc == $size) || (index($buffer,"\r") >= 0) ) {
                $may_be_present = 1;
            }
            else {
                if ( $buffer !~ /$regex/o ) {
                    $may_be_present = 0;
                }
            }
        }
    }

    return $may_be_present;
}


=head2 $file->reset()

Resets the file back to the beginning.  This is only called if
C<may_be_present()> is true, but not always if C<may_be_present()>
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

    if ( $self->{fh} ) {
        if ( !close($self->{fh}) && $App::Ack::report_bad_filenames ) {
            App::Ack::warn( $self->name() . ": $!" );
        }
        $self->{fh} = undef;
    }

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
