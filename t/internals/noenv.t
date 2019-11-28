#!perl

use strict;
use warnings;

use Test::More tests => 3;

use lib 't';
use Util;

use App::Ack::ConfigLoader;
use Cwd qw( realpath );
use File::Spec ();
use File::Temp ();

sub is_global_file {
    my ( $filename ) = @_;

    return unless -f $filename;

    my ( undef, $dir ) = File::Spec->splitpath($filename);
    $dir = File::Spec->canonpath($dir);

    my (undef, $wd) = File::Spec->splitpath(getcwd_clean(), 1);
    $wd = File::Spec->canonpath($wd);

    return $wd !~ /^\Q$dir\E/;
}

sub remove_defaults_and_globals {
    my ( @sources ) = @_;

    return grep {
        $_->{name} ne 'Defaults' && !is_global_file($_->{name})
    } @sources;
}

prep_environment();

my $wd = getcwd_clean() or die;

my $tempdir = File::Temp->newdir;

safe_chdir( $tempdir->dirname );

write_file( '.ackrc', <<'ACKRC' );
--type-add=perl:ext:pl,t,pm
ACKRC

subtest 'without --noenv' => sub {
    plan tests => 1;

    local @ARGV = ('-f', 'lib/');

    my @sources = App::Ack::ConfigLoader::retrieve_arg_sources();
    @sources    = remove_defaults_and_globals(@sources);

    is_deeply( \@sources, [
        {
            name     => File::Spec->canonpath(realpath(File::Spec->catfile($tempdir->dirname, '.ackrc'))),
            contents => [ '--type-add=perl:ext:pl,t,pm' ],
            project  => 1,
            is_ackrc => 1,
        },
        {
            name     => 'ARGV',
            contents => ['-f', 'lib/'],
        },
    ], 'Get back a long list of arguments' );
};

subtest 'with --noenv' => sub {
    plan tests => 1;

    local @ARGV = ('--noenv', '-f', 'lib/');

    my @sources = App::Ack::ConfigLoader::retrieve_arg_sources();
    @sources    = remove_defaults_and_globals(@sources);

    is_deeply( \@sources, [
        {
            name     => 'ARGV',
            contents => ['-f', 'lib/'],
        },
    ], 'Short list comes back because of --noenv' );
};

subtest '--noenv in config' => sub {
    plan tests => 3;

    append_file( '.ackrc', "--noenv\n" );

    my ( $stdout, $stderr ) = run_ack_with_stderr('--env', 'perl');
    is_empty_array( $stdout );
    is( @{$stderr}, 1 );
    like( $stderr->[0], qr/--noenv found in (?:.*)[.]ackrc/ ) or diag(explain($stderr));
};

safe_chdir( $wd ); # Go back to the original directory to avoid warnings
