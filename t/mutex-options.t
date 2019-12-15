#!perl

use strict;
use warnings;

use Test::More tests => 196;
use lib 't';
use Util;

prep_environment();

my $file = 't/text/raven.txt';
my $word = 'nevermore';


# Order doesn't matter.  They are reported in alphabetical order.
for my $opt ( qw( -p --proximate ) ) {
    are_mutually_exclusive( '-f', $opt, ['-f', $opt] );
    are_mutually_exclusive( '-f', $opt, [$opt, '-f'] );
}

# Check for abbreviations. https://github.com/beyondgrep/ack3/issues/57
for my $opt ( qw( --pro --prox --proxima --proximat --proximate ) ) {
    are_mutually_exclusive( '-f', '--proximate',
        ['-f', $opt, '4'],
        ['-f', "$opt=4"],
    );
}

# XXX Should also handle --files-with-matches and --files-without-matches.  See https://github.com/beyondgrep/ack3/issues/57
are_mutually_exclusive('-l', '-L', ['-l', '-L', $word, $file]);
for my $opt ( qw( -l -L ) ) {
    are_mutually_exclusive( $opt, '-o', [$opt, '-o', $word, $file] );
    are_mutually_exclusive( $opt, '--passthru', [$opt, '--passthru', $word, $file] );
    are_mutually_exclusive( $opt, '--output', [$opt, '--output', '$&', $word, $file] );
    are_mutually_exclusive( $opt, '--output', [$opt, '--output=$&', $word, $file] );
    are_mutually_exclusive( $opt, '-h', [$opt, '-h', $word, $file] );
    are_mutually_exclusive( $opt, '--with-filename', [$opt, '--with-filename', $word, $file] );
    are_mutually_exclusive( $opt, '--no-filename', [$opt, '--no-filename', $word, $file] );
    are_mutually_exclusive( $opt, '--column', [$opt, '--column', $word, $file] );
    are_mutually_exclusive( $opt, '-A', [$opt, '-A', 1, $word, $file] );
    are_mutually_exclusive( $opt, '--after-context', [$opt, '--after-context', 1, $word, $file] );
    are_mutually_exclusive( $opt, '--after-context', [$opt, '--after-context=1', $word, $file] );
    are_mutually_exclusive( $opt, '-B', [$opt, '-B', 1, $word, $file] );
    are_mutually_exclusive( $opt, '--before-context', [$opt, '--before-context', 1, $word, $file] );
    are_mutually_exclusive( $opt, '--before-context', [$opt, '--before-context=1', $word, $file] );
    are_mutually_exclusive( $opt, '-C', [$opt, '-C', 1, $word, $file] );
    are_mutually_exclusive( $opt, '--context', [$opt, '--context', 1, $word, $file] );
    are_mutually_exclusive( $opt, '--context', [$opt, '--context=1', $word, $file] );
    are_mutually_exclusive( $opt, '--heading', [$opt, '--heading', $word, $file] );
    are_mutually_exclusive( $opt, '--break', [$opt, '--break', $word, $file] );
    are_mutually_exclusive( $opt, '--group', [$opt, '--group', $word, $file] );
    are_mutually_exclusive( $opt, '-f', [$opt, '-f', $file] );
    are_mutually_exclusive( $opt, '-g', [$opt, '-g', $word, $file] );
    are_mutually_exclusive( $opt, '--show-types', [$opt, '--show-types', $word, $file] );
}

# -o
are_mutually_exclusive( '-o', '--output',
    ['-o', '--output', '$&', $word, $file],
    ['-o', '--output=$&', $word, $file],
);
are_mutually_exclusive('-o', '-c', ['-o', '-c', $word, $file]);
are_mutually_exclusive('-o', '--count', ['-o', '--count', $word, $file]);
are_mutually_exclusive('-o', '--column', ['-o', '--column', $word, $file]);
are_mutually_exclusive('-o', '-A', ['-o', '-A', 1, $word, $file]);
are_mutually_exclusive('-o', '--after-context', ['-o', '--after-context', 1, $word, $file]);
are_mutually_exclusive('-o', '--after-context', ['-o', '--after-context=1', $word, $file]);
are_mutually_exclusive('-o', '-B', ['-o', '-B', 1, $word, $file]);
are_mutually_exclusive('-o', '--before-context', ['-o', '--before-context', 1, $word, $file]);
are_mutually_exclusive('-o', '--before-context', ['-o', '--before-context=1', $word, $file]);
are_mutually_exclusive('-o', '-C', ['-o', '-C', 1, $word, $file]);
are_mutually_exclusive('-o', '--context', ['-o', '--context', 1, $word, $file]);
are_mutually_exclusive('-o', '--context', ['-o', '--context=1', $word, $file]);
are_mutually_exclusive('-o', '-f', ['-o', '-f', $word, $file]);
are_mutually_exclusive('-o', '--passthru', ['-o', '--passthru', $word, $file]);

# --passthru
are_mutually_exclusive('--passthru', '--output', ['--passthru', '--output', '$&', $word, $file]);
are_mutually_exclusive('--passthru', '--output', ['--passthru', '--output=$&', $word, $file]);
are_mutually_exclusive('--passthru', '-m', ['--passthru', '-m', 1, $word, $file]);
are_mutually_exclusive('--passthru', '--max-count', ['--passthru', '--max-count', 1, $word, $file]);
are_mutually_exclusive('--passthru', '--max-count', ['--passthru', '--max-count=1', $word, $file]);
are_mutually_exclusive('--passthru', '-1', ['--passthru', '-1', $word, $file]);
are_mutually_exclusive('--passthru', '-c', ['--passthru', '-c', $word, $file]);
are_mutually_exclusive('--passthru', '--count', ['--passthru', '--count', $word, $file]);
are_mutually_exclusive('--passthru', '-A', ['--passthru', '-A', 1, $word, $file]);
are_mutually_exclusive('--passthru', '--after-context', ['--passthru', '--after-context', 1, $word, $file]);
are_mutually_exclusive('--passthru', '--after-context', ['--passthru', '--after-context=1', $word, $file]);
are_mutually_exclusive('--passthru', '-B', ['--passthru', '-B', 1, $word, $file]);
are_mutually_exclusive('--passthru', '--before-context', ['--passthru', '--before-context', 1, $word, $file]);
are_mutually_exclusive('--passthru', '--before-context', ['--passthru', '--before-context=1', $word, $file]);
are_mutually_exclusive('--passthru', '-C', ['--passthru', '-C', 1, $word, $file]);
are_mutually_exclusive('--passthru', '--context', ['--passthru', '--context', 1, $word, $file]);
are_mutually_exclusive('--passthru', '--context', ['--passthru', '--context=1', $word, $file]);
are_mutually_exclusive('--passthru', '-f', ['--passthru', '-f', $word, $file]);
are_mutually_exclusive('--passthru', '-g', ['--passthru', '-g', $word, $file]);
are_mutually_exclusive('--passthru', '--column', ['--passthru', '--column', $word, $file]);
are_mutually_exclusive('--passthru', '-v', ['--passthru', '-v', $word, $file]);
are_mutually_exclusive('--passthru', '-o', ['--passthru', '-o', $word, $file]);
are_mutually_exclusive('--passthru', '--output', ['--passthru', '--output', $word, $file]);

# --output
for my $opt ( qw( -f -g -c --count ) ) {
    are_mutually_exclusive('--output', $opt,
        ['--output', '$&', $opt, $word, $file],
        ['--output=$&', $opt, $word, $file],
    );
}

are_mutually_exclusive('--output', '-A', ['--output=$&', '-A2', $word, $file]);
are_mutually_exclusive('--output', '-B', ['--output=$&', '-B2', $word, $file]);
are_mutually_exclusive('--output', '-C', ['--output=$&', '-C2', $word, $file]);
are_mutually_exclusive('--output', '--after-context', ['--output=$&', '--after-context=2', $word, $file]);
are_mutually_exclusive('--output', '--before-context', ['--output=$&', '--before-context=2', $word, $file]);
are_mutually_exclusive('--output', '--context', ['--output=$&', '--context=2', $word, $file]);

# --match
for my $opt ( qw( -f -g ) ) {
    are_mutually_exclusive('--match', $opt,
        ['--match', $word, $opt, $file],
        ['--match=science', $opt, $file],
    );
}

# --max-count
for my $opt ( qw( -1 -c -f -g ) ) {
    are_mutually_exclusive( '-m', $opt, ['-m', 1, $opt, $word, $file] );
    are_mutually_exclusive( '--max-count', $opt,
        ['--max-count', 1, $opt, $word, $file],
        ['--max-count=1', $opt, $word, $file],
    );
}

for my $opt ( qw( -h --no-filename ) ) {
    are_mutually_exclusive( $opt, '-f', [$opt, '-f', $word, $file] );
    are_mutually_exclusive( $opt, '-g', [$opt, '-g', $word, $file] );
}

# -H/--with-filename
for my $opt ( qw( -H --with-filename ) ) {
    are_mutually_exclusive( $opt, '-f', [ $opt, '-f', $word, $file] );
    are_mutually_exclusive( $opt, '-g', [ $opt, '-g', $word, $file] );
}

# -c/--count
for my $opt ( qw( -c --count ) ) {
    are_mutually_exclusive( $opt, '--column', [ $opt, '--column', $word, $file ] );
    are_mutually_exclusive( $opt, '-A', [ $opt, '-A', 1, $word, $file ] );
    are_mutually_exclusive( $opt, '--after-context', [ $opt, '--after-context', 1, $word, $file ] );
    are_mutually_exclusive( $opt, '-B', [ $opt, '-B', 1, $word, $file ] );
    are_mutually_exclusive( $opt, '--before-context', [ $opt, '--before-context', 1, $word, $file ] );
    are_mutually_exclusive( $opt, '-C', [ $opt, '-C', 1, $word, $file ] );
    are_mutually_exclusive( $opt, '--context', [ $opt, '--context', 1, $word, $file ] );
    are_mutually_exclusive( $opt, '--heading', [ $opt, '--heading', $word, $file ] );
    are_mutually_exclusive( $opt, '--group', [ $opt, '--group', $word, $file ] );
    are_mutually_exclusive( $opt, '--break', [ $opt, '--break', $word, $file ] );
    are_mutually_exclusive( $opt, '-f', [ $opt, '-f', $word, $file ] );
    are_mutually_exclusive( $opt, '-g', [ $opt, '-g', $word, $file ] );
}

# -A/-B/-C/--after-context/--before-context/--context
for my $opt ( qw( -A -B -C --after-context --before-context --context ) ) {
    are_mutually_exclusive( $opt, '-f', [$opt, 1, '-f', $word, $file] );
    are_mutually_exclusive( $opt, '-g', [$opt, 1, '-g', $word, $file] );
    are_mutually_exclusive( $opt, '-p', [$opt, 1, '-p', $word, $file] );
}

# -f/-g
are_mutually_exclusive('-f', '-g', ['-f', '-g', $word, $file]);
for my $opt ( qw( -f -g ) ) {
    are_mutually_exclusive( $opt, '--group',   [$opt, '--group', $word, $file] );
    are_mutually_exclusive( $opt, '--heading', [$opt, '--heading', $word, $file] );
    are_mutually_exclusive( $opt, '--break',   [$opt, '--break', $word, $file] );
    are_mutually_exclusive( $opt, '--column',  [$opt, '--column', $word, $file] );
}

# -x
are_mutually_exclusive( '-x', '--files-from', ['-x', '--files-from', $word, $file] );
for my $opt ( qw( -f -g ) ) {
    are_mutually_exclusive( $opt, '-x',   [$opt, '-x', $word, $file] );
    are_mutually_exclusive( $opt, '--files-from', [$opt, '--files-from', $word, $file] );
}

subtest q{Verify that "options" that follow -- aren't factored into the mutual exclusivity} => sub {
    my ( $stdout, $stderr ) = run_ack_with_stderr('-A', 5, $word, $file, '--', '-l');
    ok(@{$stdout} > 0, 'Some lines should appear on standard output');
    is(scalar(@{$stderr}), 1, 'A single line should be present on standard error');
    like($stderr->[0], qr/No such file or directory/, 'The error message should indicate a missing file (-l is a filename here, not an option)');
    is(get_rc(), 0, 'The ack command should not fail');
};

subtest q{Verify that mutex options in different sources don't cause a problem} => sub {
    my $ackrc = <<'HERE';
--group
HERE

    my @stdout = run_ack('--count', $file, {
        ackrc => \$ackrc,
    });
    ok(@stdout > 0, 'Some lines should appear on standard output');
};

done_testing();

# Do this without system().
sub are_mutually_exclusive {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $opt1    = shift;
    my $opt2    = shift;
    my @argsets = @_;

    @argsets or die 'Must pass argsets';

    for my $argset ( @argsets ) {
        my @args = @{$argset};

        my ( $stdout, $stderr ) = run_ack_with_stderr(@args);

        subtest subtest_name( $opt1, $opt2, $argset ) => sub {
            plan tests => 4;

            isnt( get_rc(), 0, 'The ack command should fail' );
            is_empty_array( $stdout, 'No lines should be present on standard output' );
            is( scalar(@{$stderr}), 1, 'A single line should be present on standard error' );

            my $opt1_re = quotemeta($opt1);
            my $opt2_re = quotemeta($opt2);

            my $error = $stderr->[0] || ''; # avoid undef warnings
            if ( $error =~ /Options '$opt1_re' and '$opt2_re' can't be used together/ ||
                $error =~ /Options '$opt2_re' and '$opt1_re' can't be used together/ ) {

                pass( qq{Error message resembles "Options '$opt1' and '$opt2' can't be used together"} );
            }
            else {
                fail( qq{Error message does not resemble "Options '$opt1' and '$opt2' can't be used together"} );
                diag("Error message: '$error'");
            }
        };
    }

    return;
}
