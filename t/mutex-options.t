#!perl -T

use strict;
use warnings;

use Test::More tests => 187;
use lib 't';
use Util;

prep_environment();

my $file = 't/text/raven.txt';
my $word = 'nevermore';

# -l/--files-with-matches
are_mutually_exclusive('-l', '-L', ['-l', '-L', $word, $file]);
are_mutually_exclusive('-l', '-o', ['-l', '-o', $word, $file]);
are_mutually_exclusive('-l', '--passthru', ['-l', '--passthru', $word, $file]);
are_mutually_exclusive('-l', '--output', ['-l', '--output', '$&', $word, $file]);
are_mutually_exclusive('-l', '--output', ['-l', '--output=$&', $word, $file]);
are_mutually_exclusive('-l', '--max-count', ['-l', '--max-count', 1, $word, $file]);
are_mutually_exclusive('-l', '--max-count', ['-l', '--max-count=1', $word, $file]);
are_mutually_exclusive('-l', '-h', ['-l', '-h', $word, $file]);
are_mutually_exclusive('-l', '--with-filename', ['-l', '--with-filename', $word, $file]);
are_mutually_exclusive('-l', '--no-filename', ['-l', '--no-filename', $word, $file]);
are_mutually_exclusive('-l', '--column', ['-l', '--column', $word, $file]);
are_mutually_exclusive('-l', '-A', ['-l', '-A', 1, $word, $file]);
are_mutually_exclusive('-l', '--after-context', ['-l', '--after-context', 1, $word, $file]);
are_mutually_exclusive('-l', '--after-context', ['-l', '--after-context=1', $word, $file]);
are_mutually_exclusive('-l', '-B', ['-l', '-B', 1, $word, $file]);
are_mutually_exclusive('-l', '--before-context', ['-l', '--before-context', 1, $word, $file]);
are_mutually_exclusive('-l', '--before-context', ['-l', '--before-context=1', $word, $file]);
are_mutually_exclusive('-l', '-C', ['-l', '-C', 1, $word, $file]);
are_mutually_exclusive('-l', '--context', ['-l', '--context', 1, $word, $file]);
are_mutually_exclusive('-l', '--context', ['-l', '--context=1', $word, $file]);
are_mutually_exclusive('-l', '--heading', ['-l', '--heading', $word, $file]);
are_mutually_exclusive('-l', '--break', ['-l', '--break', $word, $file]);
are_mutually_exclusive('-l', '--group', ['-l', '--group', $word, $file]);
are_mutually_exclusive('-l', '-f', ['-l', '-f', $file]);
are_mutually_exclusive('-l', '-g', ['-l', '-g', $word, $file]);
are_mutually_exclusive('-l', '--show-types', ['-l', '--show-types', $word, $file]);

# -L/--files-without-matches
are_mutually_exclusive('-L', '-l', ['-L', '-l', $word, $file]);
are_mutually_exclusive('-L', '-o', ['-L', '-o', $word, $file]);
are_mutually_exclusive('-L', '--passthru', ['-L', '--passthru', $word, $file]);
are_mutually_exclusive('-L', '--output', ['-L', '--output', '$&', $word, $file]);
are_mutually_exclusive('-L', '--output', ['-L', '--output=$&', $word, $file]);
are_mutually_exclusive('-L', '--max-count', ['-L', '--max-count', 1, $word, $file]);
are_mutually_exclusive('-L', '--max-count', ['-L', '--max-count=1', $word, $file]);
are_mutually_exclusive('-L', '-h', ['-L', '-h', $word, $file]);
are_mutually_exclusive('-L', '--with-filename', ['-L', '--with-filename', $word, $file]);
are_mutually_exclusive('-L', '--no-filename', ['-L', '--no-filename', $word, $file]);
are_mutually_exclusive('-L', '--column', ['-L', '--column', $word, $file]);
are_mutually_exclusive('-L', '-A', ['-L', '-A', 1, $word, $file]);
are_mutually_exclusive('-L', '--after-context', ['-L', '--after-context', 1, $word, $file]);
are_mutually_exclusive('-L', '--after-context', ['-L', '--after-context=1', $word, $file]);
are_mutually_exclusive('-L', '-B', ['-L', '-B', 1, $word, $file]);
are_mutually_exclusive('-L', '--before-context', ['-L', '--before-context', 1, $word, $file]);
are_mutually_exclusive('-L', '--before-context', ['-L', '--before-context=1', $word, $file]);
are_mutually_exclusive('-L', '-C', ['-L', '-C', 1, $word, $file]);
are_mutually_exclusive('-L', '--context', ['-L', '--context', 1, $word, $file]);
are_mutually_exclusive('-L', '--context', ['-L', '--context=1', $word, $file]);
are_mutually_exclusive('-L', '--heading', ['-L', '--heading', $word, $file]);
are_mutually_exclusive('-L', '--break', ['-L', '--break', $word, $file]);
are_mutually_exclusive('-L', '--group', ['-L', '--group', $word, $file]);
are_mutually_exclusive('-L', '-f', ['-L', '-f', $file]);
are_mutually_exclusive('-L', '-g', ['-L', '-g', $word, $file]);
are_mutually_exclusive('-L', '--show-types', ['-L', '--show-types', $word, $file]);
are_mutually_exclusive('-L', '-c', ['-L', '-c', $word, $file]);
are_mutually_exclusive('-L', '--count', ['-L', '--count', $word, $file]);

# -o
are_mutually_exclusive('-o', '--output', ['-o', '--output', '$&', $word, $file]);
are_mutually_exclusive('-o', '--output', ['-o', '--output=$&', $word, $file]);
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

# --passthru
are_mutually_exclusive('--passthru', '--output', ['--passthru', '--output', '$&', $word, $file]);
are_mutually_exclusive('--passthru', '--output', ['--passthru', '--output=$&', $word, $file]);
are_mutually_exclusive('--passthru', '-m', ['--passthru', '-m', 1, $word, $file]);
are_mutually_exclusive('--passthru', '--max-count', ['--passthru', '--max-count', 1, $word, $file]);
are_mutually_exclusive('--passthru', '--max-count', ['--passthru', '--max-count=1', $word, $file]);
are_mutually_exclusive('--passthru', '-1', ['--passthru', '-1', $word, $file]);
are_mutually_exclusive('--passthru', '-c', ['--passthru', '-c', $word, $file]);
are_mutually_exclusive('--passthru', '--count', ['--passthru', '--count', $word, $file]);
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

# --output
are_mutually_exclusive('--output', '-c', ['--output', '$&', '-c', $word, $file]);
are_mutually_exclusive('--output', '--count', ['--output', '$&', '--count', $word, $file]);
are_mutually_exclusive('--output', '-f', ['--output', '$&', '-f', $file]);
are_mutually_exclusive('--output', '-g', ['--output', '$&', '-g', $word, $file]);
are_mutually_exclusive('--output', '-c', ['--output=$&', '-c', $word, $file]);
are_mutually_exclusive('--output', '--count', ['--output=$&', '--count', $word, $file]);
are_mutually_exclusive('--output', '-f', ['--output=$&', '-f', $file]);
are_mutually_exclusive('--output', '-g', ['--output=$&', '-g', $word, $file]);
are_mutually_exclusive('--output', '-A', ['--output=$&', '-A2', $word, $file]);
are_mutually_exclusive('--output', '-B', ['--output=$&', '-B2', $word, $file]);
are_mutually_exclusive('--output', '-C', ['--output=$&', '-C2', $word, $file]);
are_mutually_exclusive('--output', '--after-context', ['--output=$&', '--after-context=2', $word, $file]);
are_mutually_exclusive('--output', '--before-context', ['--output=$&', '--before-context=2', $word, $file]);
are_mutually_exclusive('--output', '--context', ['--output=$&', '--context=2', $word, $file]);

# --match
are_mutually_exclusive('--match', '-f', ['--match', $word, '-f', $file]);
are_mutually_exclusive('--match', '-g', ['--match', $word, '-g', $file]);
are_mutually_exclusive('--match', '-f', ['--match=science', '-f', $file]);
are_mutually_exclusive('--match', '-g', ['--match=science', '-g', $file]);

# --max-count
are_mutually_exclusive('-m', '-1', ['-m', 1, '-1', $word, $file]);
are_mutually_exclusive('-m', '-c', ['-m', 1, '-c', $word, $file]);
are_mutually_exclusive('-m', '-f', ['-m', 1, '-f', $word, $file]);
are_mutually_exclusive('-m', '-g', ['-m', 1, '-g', $word, $file]);
are_mutually_exclusive('--max-count', '-1', ['--max-count', 1, '-1', $word, $file]);
are_mutually_exclusive('--max-count', '-c', ['--max-count', 1, '-c', $word, $file]);
are_mutually_exclusive('--max-count', '-f', ['--max-count', 1, '-f', $word, $file]);
are_mutually_exclusive('--max-count', '-g', ['--max-count', 1, '-g', $word, $file]);
are_mutually_exclusive('--max-count', '-1', ['--max-count=1', '-1', $word, $file]);
are_mutually_exclusive('--max-count', '-c', ['--max-count=1', '-c', $word, $file]);
are_mutually_exclusive('--max-count', '-f', ['--max-count=1', '-f', $word, $file]);
are_mutually_exclusive('--max-count', '-g', ['--max-count=1', '-g', $word, $file]);

# -h/--no-filename
are_mutually_exclusive('-h', '-H', ['-h', '-H', $word, $file]);
are_mutually_exclusive('-h', '--with-filename', ['-h', '--with-filename', $word, $file]);
are_mutually_exclusive('-h', '-f', ['-h', '-f', $word, $file]);
are_mutually_exclusive('-h', '-g', ['-h', '-g', $word, $file]);
are_mutually_exclusive('-h', '--group', ['-h', '--group', $word, $file]);
are_mutually_exclusive('-h', '--heading', ['-h', '--heading', $word, $file]);

are_mutually_exclusive('--no-filename', '-H', ['--no-filename', '-H', $word, $file]);
are_mutually_exclusive('--no-filename', '--with-filename', ['--no-filename', '--with-filename', $word, $file]);
are_mutually_exclusive('--no-filename', '-f', ['--no-filename', '-f', $word, $file]);
are_mutually_exclusive('--no-filename', '-g', ['--no-filename', '-g', $word, $file]);
are_mutually_exclusive('--no-filename', '--group', ['--no-filename', '--group', $word, $file]);
are_mutually_exclusive('--no-filename', '--heading', ['--no-filename', '--heading', $word, $file]);

# -H/--with-filename
are_mutually_exclusive('-H', '-h', ['-H', '-h', $word, $file]);
are_mutually_exclusive('-H', '--no-filename', ['-H', '--no-filename', $word, $file]);
are_mutually_exclusive('-H', '-f', ['-H', '-f', $word, $file]);
are_mutually_exclusive('-H', '-g', ['-H', '-g', $word, $file]);
are_mutually_exclusive('--with-filename', '-h', ['--with-filename', '-h', $word, $file]);
are_mutually_exclusive('--with-filename', '--no-filename', ['--with-filename', '--no-filename', $word, $file]);
are_mutually_exclusive('--with-filename', '-f', ['--with-filename', '-f', $word, $file]);
are_mutually_exclusive('--with-filename', '-g', ['--with-filename', '-g', $word, $file]);

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

# --column
are_mutually_exclusive('--column', '-f', ['--column', '-f', $word, $file]);
are_mutually_exclusive('--column', '-g', ['--column', '-g', $word, $file]);

# -A/-B/-C/--after-context/--before-context/--context
for my $opt ( qw( -A -B -C --after-context --before-context --context ) ) {
    are_mutually_exclusive( $opt, '-f', [$opt, 1, '-f', $word, $file] );
    are_mutually_exclusive( $opt, '-g', [$opt, 1, '-g', $word, $file] );
}

# -f
are_mutually_exclusive('-f', '-g', ['-f', '-g', $word, $file]);
are_mutually_exclusive('-f', '--group', ['-f', '--group', $word, $file]);
are_mutually_exclusive('-f', '--heading', ['-f', '--heading', $word, $file]);
are_mutually_exclusive('-f', '--break', ['-f', '--break', $word, $file]);

# -g
are_mutually_exclusive('-g', '--group', ['-g', '--group', $word, $file]);
are_mutually_exclusive('-g', '--heading', ['-g', '--heading', $word, $file]);
are_mutually_exclusive('-g', '--break', ['-g', '--break', $word, $file]);

subtest q{Verify that "options" that follow -- aren't factored into the mutual exclusivity} => sub {
    my ( $stdout, $stderr ) = run_ack_with_stderr('-A', 5, $word, $file, '--', '-l');
    ok(@{$stdout} > 0, 'Some lines should appear on standard output');
    is(scalar(@{$stderr}), 1, 'A single line should be present on standard error');
    like($stderr->[0], qr/No such file or directory/, 'The error message should indicate a missing file (-l is a filename here, not an option)');
    is(get_rc(), 0, 'The ack command should not fail');
};

subtest q{Verify that mutually exclusive options in different sources don't cause a problem} => sub {
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

    my ( $opt1, $opt2, $args ) = @_;

    my @args = @{$args};

    my ( $stdout, $stderr ) = run_ack_with_stderr(@args);

    return subtest subtest_name( $opt1, $opt2, $args ) => sub {
        plan tests => 4;

        isnt( get_rc(), 0, 'The ack command should fail' );
        is_empty_array( $stdout, 'No lines should be present on standard output' );
        is( scalar(@{$stderr}), 1, 'A single line should be present on standard error' );

        my $opt1_re = quotemeta($opt1);
        my $opt2_re = quotemeta($opt2);

        my $error = $stderr->[0] || ''; # avoid undef warnings
        if ( $error =~ /Options '$opt1_re' and '$opt2_re' are mutually exclusive/ ||
            $error =~ /Options '$opt2_re' and '$opt1_re' are mutually exclusive/ ) {

            pass( qq{Error message resembles "Options '$opt1' and '$opt2' are mutually exclusive"} );
        }
        else {
            fail( qq{Error message does not resemble "Options '$opt1' and '$opt2' are mutually exclusive"} );
            diag("Error message: '$error'");
        }
    };
}
