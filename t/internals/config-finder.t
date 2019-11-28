#!perl

use strict;
use warnings;

use lib 't';
use Util;

use Cwd qw(realpath);
use File::Spec;
use File::Temp;
use Test::Builder;
use Test::More;

use App::Ack::ConfigFinder;

my $tmpdir = $ENV{'TMPDIR'};
my $home   = $ENV{'HOME'};

for ( $tmpdir, $home ) {
    s{/$}{} if defined;
}

if ( $tmpdir && ($tmpdir =~ /^\Q$home/) ) {
    plan skip_all => "Your \$TMPDIR ($tmpdir) is set to a descendant directory of your home directory.  This test is known to fail with such a setting.  Please set your TMPDIR to something else to get this test to pass.";
    exit;
}

plan tests => 26;

# Set HOME to a known value, so we get predictable results.
local $ENV{HOME} = realpath('t/home');

# Clear the user's ACKRC so it doesn't throw out expect_ackrcs().
delete $ENV{'ACKRC'};

my $finder;
my @global_filenames = create_globals();

my @global_files = map { +{ path => $_ } } @global_filenames;
my @std_files = (@global_files, { path => File::Spec->catfile($ENV{'HOME'}, '.ackrc') });

my $wd      = getcwd_clean();
my $tempdir = File::Temp->newdir;
safe_chdir( $tempdir->dirname );

$finder = App::Ack::ConfigFinder->new;
with_home( sub {
    expect_ackrcs( \@std_files, 'having no project file should return only the top level files' );
} );

no_home( sub {
    expect_ackrcs( \@global_files, 'only system-wide ackrc is returned if HOME is not defined with no project files' );
} );

safe_mkdir( 'foo' );
safe_mkdir( File::Spec->catdir('foo', 'bar') );
safe_mkdir( File::Spec->catdir('foo', 'bar', 'baz') );
safe_chdir( File::Spec->catdir('foo', 'bar', 'baz') );

touch_ackrc( '.ackrc' );
with_home( sub {
    expect_ackrcs( [ @std_files, { project => 1, path => File::Spec->rel2abs('.ackrc') }], 'a project file in the same directory should be detected' );
} );
no_home( sub {
    expect_ackrcs( [ @global_files, { project => 1, path => File::Spec->rel2abs('.ackrc') } ], 'a project file in the same directory should be detected' );
} );

unlink '.ackrc';

my $project_file = File::Spec->catfile($tempdir->dirname, 'foo', 'bar', '.ackrc');
touch_ackrc( $project_file );
with_home( sub {
    expect_ackrcs( [ @std_files, { project => 1, path => $project_file } ], 'a project file in the parent directory should be detected' );
} );
no_home( sub {
    expect_ackrcs( [ @global_files, { project => 1, path => $project_file } ], 'a project file in the parent directory should be detected' );
} );
unlink $project_file;

$project_file = File::Spec->catfile($tempdir->dirname, 'foo', '.ackrc');
touch_ackrc( $project_file );
with_home( sub {
    expect_ackrcs( [ @std_files, { project => 1, path => $project_file } ], 'a project file in the grandparent directory should be detected' );
} );
no_home( sub {
    expect_ackrcs( [ @global_files, { project => 1, path => $project_file } ], 'a project file in the grandparent directory should be detected' );
} );

touch_ackrc( '.ackrc' );

with_home( sub {
    expect_ackrcs( [ @std_files, { project => 1, path => File::Spec->rel2abs('.ackrc') } ], 'a project file in the same directory should be detected, even with another one above it' );
} );
no_home( sub {
    expect_ackrcs( [ @global_files, { project => 1, path => File::Spec->rel2abs('.ackrc') } ], 'a project file in the same directory should be detected, even with another one above it' );
} );

unlink '.ackrc';
unlink $project_file;

touch_ackrc( '_ackrc' );
with_home( sub {
    expect_ackrcs( [ @std_files, { project => 1, path => File::Spec->rel2abs('_ackrc') } ], 'a project file in the same directory should be detected' );
} );
no_home( sub {
    expect_ackrcs( [ @global_files, { project => 1, path => File::Spec->rel2abs('_ackrc') } ], 'a project file in the same directory should be detected' );
} );

unlink '_ackrc';

$project_file = File::Spec->catfile($tempdir->dirname, 'foo', '_ackrc');
touch_ackrc( $project_file );
with_home( sub {
    expect_ackrcs( [ @std_files, { project => 1, path => $project_file } ], 'a project file in the grandparent directory should be detected' );
} );
no_home( sub {
    expect_ackrcs( [ @global_files, { project => 1, path => $project_file } ], 'a project file in the grandparent directory should be detected' );
} );

touch_ackrc( '_ackrc' );
with_home( sub { expect_ackrcs( [ @std_files, { project => 1, path => File::Spec->rel2abs('_ackrc') } ], 'a project file in the same directory should be detected, even with another one above it' );
} );
no_home( sub {
    expect_ackrcs( [ @global_files, { project => 1, path => File::Spec->rel2abs('_ackrc') } ], 'a project file in the same directory should be detected, even with another one above it' );
} );

unlink $project_file;
touch_ackrc( '.ackrc' );

do {
    my $finder_fn = sub {
        my $ok = eval { $finder->find_config_files };
        my $err = $@;
        ok( !$ok, '.ackrc + _ackrc is error' );
        like( $err, qr/contains both \.ackrc and _ackrc/, 'Got the expected error' );
    };
    with_home( $finder_fn );
    no_home( $finder_fn );

    unlink '.ackrc';
    $project_file = File::Spec->catfile($tempdir->dirname, 'foo', '.ackrc');
    touch_ackrc( $project_file );
    with_home( sub {
        expect_ackrcs( [ @std_files, { project => 1, path => File::Spec->rel2abs('_ackrc') }], 'a lower-level _ackrc should be preferred to a higher-level .ackrc' );
    } );
    no_home( sub {
        expect_ackrcs( [ @global_files, { project => 1, path => File::Spec->rel2abs('_ackrc') } ], 'a lower-level _ackrc should be preferred to a higher-level .ackrc' );
    } );

    unlink '_ackrc';
};

do {
    my $test_home = File::Spec->catdir( $tempdir->dirname, 'foo' );
    local $ENV{'HOME'} = $test_home;

    my $user_file = File::Spec->catfile( $test_home, '.ackrc');
    touch_ackrc( $user_file );

    expect_ackrcs( [ @global_files, { path => $user_file } ], q{Don't load the same ackrc file twice} );
    unlink($user_file);
};

do {
    safe_chdir( $tempdir->dirname );
    local $ENV{'HOME'} = File::Spec->catfile($tempdir->dirname, 'foo');

    my $user_file = File::Spec->catfile($ENV{'HOME'}, '.ackrc');
    touch_ackrc( $user_file );

    my $ackrc = create_tempfile();
    local $ENV{'ACKRC'} = $ackrc->filename;

    expect_ackrcs( [ @global_files, { path => $ackrc->filename } ], q{ACKRC overrides user's HOME ackrc} );
    unlink $ackrc->filename;

    expect_ackrcs( [ @global_files, { path => $user_file } ], q{ACKRC doesn't override if it doesn't exist} );

    touch_ackrc( $ackrc->filename );
    safe_chdir( 'foo' );
    expect_ackrcs( [ @global_files, { path => $ackrc->filename}, { project => 1, path => $user_file } ], q{~/.ackrc should still be found as a project ackrc} );
    unlink $ackrc->filename;
};

safe_chdir( $wd );
clean_up_globals();

exit 0;


sub with_home {
    my ( $fn ) = @_;

    $fn->();

    return;
}


sub no_home {
    my ( $fn ) = @_;

    # We have to manually store the value of HOME because localized
    # delete isn't supported until Perl 5.12.0.
    my $home_saved = delete $ENV{HOME};
    $fn->();
    $ENV{HOME} = $home_saved;

    return;
}

sub expect_ackrcs {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $expected = shift;
    my $name     = shift;

    my @got      = $finder->find_config_files;
    my @expected = @{$expected};

    foreach my $element (@got, @expected) {
        $element->{'path'} = realpath($element->{'path'});
    }
    is_deeply( \@got, \@expected, $name ) or diag(explain(got=>\@got,expected=>\@expected));

    return;
}
