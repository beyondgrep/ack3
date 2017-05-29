#!perl -T

use strict;
use warnings;
use lib 't';
use Util;

use Test::More tests => 28;

use App::Ack::Filter::Default;
use App::Ack::ConfigLoader;

delete @ENV{qw( PAGER ACK_PAGER ACK_PAGER_COLOR ACK_OPTIONS )};

my %defaults = (
    'break'    => undef,
    color      => undef,
    column     => undef,
    count      => undef,
    f          => undef,
    files_from => undef,
    filters    => [ App::Ack::Filter::Default->new ],
    follow     => undef,
    g          => undef,
    h          => undef,
    H          => undef,
    heading    => undef,
    l          => undef,
    L          => undef,
    m          => undef,
    n          => undef,
    output     => undef,
    pager      => undef,
    passthru   => undef,
    print0     => undef,
    proximate  => undef,
    Q          => undef,
    regex      => undef,
    s          => undef,
    show_types => undef,
    sort_files => undef,
    u          => undef,
    v          => undef,
    w          => undef,
);

test_loader(
    expected_opts    => { %defaults },
    'empty inputs should result in default outputs'
);

# --after_context, --before_context
for my $option ( qw( after_context before_context ) ) {
    my $long_arg = $option;
    $long_arg =~ s/_/-/ or die;

    test_loader(
        argv             => [ "--$long_arg=15" ],
        expected_opts    => { %defaults, $option => 15 },
        "--$long_arg=15 should set $option to 15",
    );

    test_loader(
        argv             => [ "--$long_arg=0" ],
        expected_opts    => { %defaults, $option => 0 },
        "--$long_arg=0 should set $option to 0",
    );

    test_loader(
        argv             => [ "--$long_arg" ],
        expected_opts    => { %defaults, $option => 2 },
        "--$long_arg without a value should default $option to 2",
    );

    test_loader(
        argv             => [ "--$long_arg=-43" ],
        expected_opts    => { %defaults, $option => 2 },
        "--$long_arg with a negative value should default $option to 2",
    );

    my $short_arg = '-' . uc substr( $option, 0, 1 );
    test_loader(
        argv             => [ $short_arg, 15 ],
        expected_opts    => { %defaults, $option => 15 },
        "$short_arg 15 should set $option to 15",
    );

    test_loader(
        argv             => [ $short_arg, 0 ],
        expected_opts    => { %defaults, $option => 0 },
        "$short_arg 0 should set $option to 0",
    );

    test_loader(
        argv             => [ $short_arg ],
        expected_opts    => { %defaults, $option => 2 },
        "$short_arg without a value should default $option to 2",
    );

    test_loader(
        argv             => [ $short_arg, '-43' ],
        expected_opts    => { %defaults, $option => 2 },
        "$short_arg with a negative value should default $option to 2",
    );
}

test_loader(
    argv             => ['-C', 5],
    expected_opts    => { %defaults, after_context => 5, before_context => 5 },
    '-C sets both before_context and after_context'
);

test_loader(
    argv             => ['-C'],
    expected_opts    => { %defaults, after_context => 2, before_context => 2 },
    '-C sets both before_context and after_context, with default'
);

test_loader(
    argv             => ['-C', 0],
    expected_opts    => { %defaults, after_context => 0, before_context => 0 },
    '-C sets both before_context and after_context, with zero overriding default'
);

test_loader(
    argv             => ['-C', -43],
    expected_opts    => { %defaults, after_context => 2, before_context => 2 },
    '-C with invalid value sets both before_context and after_context to default'
);

test_loader(
    argv             => ['--context=5'],
    expected_opts    => { %defaults, after_context => 5, before_context => 5 },
    '--context sets both before_context and after_context'
);

test_loader(
    argv             => ['--context'],
    expected_opts    => { %defaults, after_context => 2, before_context => 2 },
    '--context sets both before_context and after_context, with default'
);

test_loader(
    argv             => ['--context=0'],
    expected_opts    => { %defaults, after_context => 0, before_context => 0 },
    '--context sets both before_context and after_context, with zero overriding default'
);

test_loader(
    argv             => ['--context=-43'],
    expected_opts    => { %defaults, after_context => 2, before_context => 2 },
    '--context with invalid value sets both before_context and after_context to default'
);


subtest 'ACK_PAGER' => sub {
    plan tests => 3;

    local $ENV{'ACK_PAGER'} = './test-pager --skip=2';

    test_loader(
        argv             => [],
        expected_opts    => { %defaults, pager => './test-pager --skip=2' },
        'ACK_PAGER should set the default pager',
    );

    test_loader(
        argv             => ['--pager=./test-pager'],
        expected_opts    => { %defaults, pager => './test-pager' },
        '--pager should override ACK_PAGER',
    );

    test_loader(
        argv             => ['--nopager'],
        expected_opts    => { %defaults },
        '--nopager should suppress ACK_PAGER',
    );
};


subtest 'ACK_PAGER_COLOR' => sub {
    plan tests => 6;

    local $ENV{'ACK_PAGER_COLOR'} = './test-pager --skip=2';

    test_loader(
        argv             => [],
        expected_opts    => { %defaults, pager => './test-pager --skip=2' },
        'ACK_PAGER_COLOR should set the default pager',
    );

    test_loader(
        argv             => ['--pager=./test-pager'],
        expected_opts    => { %defaults, pager => './test-pager' },
        '--pager should override ACK_PAGER_COLOR',
    );

    test_loader(
        argv             => ['--nopager'],
        expected_opts    => { %defaults },
        '--nopager should suppress ACK_PAGER_COLOR',
    );

    local $ENV{'ACK_PAGER'} = './test-pager --skip=3';

    test_loader(
        argv             => [],
        expected_opts    => { %defaults, pager => './test-pager --skip=2' },
        'ACK_PAGER_COLOR should override ACK_PAGER',
    );

    test_loader(
        argv             => ['--pager=./test-pager'],
        expected_opts    => { %defaults, pager => './test-pager' },
        '--pager should override ACK_PAGER_COLOR and ACK_PAGER',
    );

    test_loader(
        argv             => ['--nopager'],
        expected_opts    => { %defaults },
        '--nopager should suppress ACK_PAGER_COLOR and ACK_PAGER',
    );
};


subtest 'PAGER' => sub {
    plan tests => 3;

    local $ENV{'PAGER'} = './test-pager';

    test_loader(
        argv             => [],
        expected_opts    => { %defaults },
        q{PAGER doesn't affect ack by default},
    );

    test_loader(
        argv             => ['--pager'],
        expected_opts    => { %defaults, pager => './test-pager' },
        'PAGER is used if --pager is specified with no argument',
    );

    test_loader(
        argv             => ['--pager=./test-pager --skip=2'],
        expected_opts    => { %defaults, pager => './test-pager --skip=2' },
        'PAGER is not used if --pager is specified with an argument',
    );
};

done_testing();

exit 0;


sub test_loader {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    die 'Must pass key/value pairs, plus a message at the end' unless @_ % 2 == 1;

    my $msg  = pop;
    my %opts = @_;

    return subtest "test_loader( $msg )" => sub {
        plan tests => 3;

        my $env           = delete $opts{env}  // '';
        my $argv          = delete $opts{argv} // [];
        my $expected_opts = delete $opts{expected_opts};

        is( scalar keys %opts, 0, 'All the keys are gone' );

        my $got_opts;
        my $got_targets;
        do {
            local $ENV{ACK_OPTIONS} = $env;
            local @ARGV = ();

            my @arg_sources = (
                { name => 'ARGV', contents => $argv },
            );

            $got_opts    = App::Ack::ConfigLoader::process_args( @arg_sources );
            $got_targets = [ @ARGV ];
        };

        is_deeply( $got_opts, $expected_opts, 'Options match' );
        is_empty_array( $got_targets, 'Got no targets' );
    };
}
