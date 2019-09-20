#!perl

use strict;
use warnings;

use Test::More;

use lib 't';
use Util;

if ( not has_io_pty() ) {
    plan skip_all => q{You need to install IO::Pty to run this test};
    exit(0);
}

plan tests => 9;

prep_environment();

NO_PAGER: {
    my @args = qw(--nocolor --sort-files -i nevermore t/text);

    my @expected = line_split( <<'HERE' );
t/text/raven.txt
55:    Quoth the Raven, "Nevermore."
62:    With such name as "Nevermore."
69:    Then the bird said, "Nevermore."
76:    Of 'Never -- nevermore.'
83:    Meant in croaking "Nevermore."
90:    She shall press, ah, nevermore!
97:    Quoth the Raven, "Nevermore."
104:    Quoth the Raven, "Nevermore."
111:    Quoth the Raven, "Nevermore."
118:    Quoth the Raven, "Nevermore."
125:    Shall be lifted--nevermore!
HERE

    my @got = run_ack_interactive(@args);

    lists_match( \@got, \@expected, 'NO_PAGER' );
}

PAGER: {
    my @args = qw(--nocolor --pager=t/test-pager --sort-files -i nevermore t/text);

    my @expected = line_split( <<'HERE' );
t/text/raven.txt
55:    Quoth the Raven, "Nevermore."
62:    With such name as "Nevermore."
69:    Then the bird said, "Nevermore."
76:    Of 'Never -- nevermore.'
83:    Meant in croaking "Nevermore."
90:    She shall press, ah, nevermore!
97:    Quoth the Raven, "Nevermore."
104:    Quoth the Raven, "Nevermore."
111:    Quoth the Raven, "Nevermore."
118:    Quoth the Raven, "Nevermore."
125:    Shall be lifted--nevermore!
HERE

    my @got = run_ack_interactive(@args);

    lists_match( \@got, \@expected, 'PAGER' );
}

PAGER_WITH_OPTS: {
    my @args = (
        '--nocolor',
        '--pager=t/test-pager --skip=2',    # --skip is an argument passed to test-pager
        '--sort-files',
        '-i',
        'nevermore',
        't/text',
    );

    my @expected = line_split( <<'HERE' );
t/text/raven.txt
62:    With such name as "Nevermore."
76:    Of 'Never -- nevermore.'
90:    She shall press, ah, nevermore!
104:    Quoth the Raven, "Nevermore."
118:    Quoth the Raven, "Nevermore."
HERE

    my @got = run_ack_interactive(@args);

    lists_match( \@got, \@expected, 'PAGER_WITH_OPTS' );
}

FORCE_NO_PAGER: {
    my @args = (
        '--nocolor',
        '--pager=t/test-pager --skip=2',    # --skip is an argument passed to test-pager
        '--nopager',
        '--sort-files',
        '-i',
        'nevermore',
        't/text',
    );

    my @expected = line_split( <<'HERE' );
t/text/raven.txt
55:    Quoth the Raven, "Nevermore."
62:    With such name as "Nevermore."
69:    Then the bird said, "Nevermore."
76:    Of 'Never -- nevermore.'
83:    Meant in croaking "Nevermore."
90:    She shall press, ah, nevermore!
97:    Quoth the Raven, "Nevermore."
104:    Quoth the Raven, "Nevermore."
111:    Quoth the Raven, "Nevermore."
118:    Quoth the Raven, "Nevermore."
125:    Shall be lifted--nevermore!
HERE

    my @got = run_ack_interactive(@args);

    lists_match( \@got, \@expected, 'FORCE_NO_PAGER' );
}

PAGER_ENV: {
    local $ENV{'ACK_PAGER'} = 't/test-pager --skip=2';
    local $TODO             = q{Setting ACK_PAGER in tests won't work for the time being};

    my @args = qw( --nocolor --sort-files -i nevermore t/text );

    my @expected = line_split( <<'HERE' );
t/text/raven.txt
62:    With such name as "Nevermore."
76:    Of 'Never -- nevermore.'
90:    She shall press, ah, nevermore!
104:    Quoth the Raven, "Nevermore."
118:    Quoth the Raven, "Nevermore."
HERE

    my @got = run_ack_interactive(@args);

    lists_match( \@got, \@expected, 'PAGER_ENV' );
}

PAGER_ENV_OVERRIDE: {
    local $ENV{'ACK_PAGER'} = 't/test-pager --skip=2';

    my @args = qw( --nocolor --nopager --sort-files -i nevermore t/text );

    my @expected = line_split( <<'HERE' );
t/text/raven.txt
55:    Quoth the Raven, "Nevermore."
62:    With such name as "Nevermore."
69:    Then the bird said, "Nevermore."
76:    Of 'Never -- nevermore.'
83:    Meant in croaking "Nevermore."
90:    She shall press, ah, nevermore!
97:    Quoth the Raven, "Nevermore."
104:    Quoth the Raven, "Nevermore."
111:    Quoth the Raven, "Nevermore."
118:    Quoth the Raven, "Nevermore."
125:    Shall be lifted--nevermore!
HERE

    my @got = run_ack_interactive(@args);

    lists_match( \@got, \@expected, 'PAGER_ENV_OVERRIDE' );
}


PAGER_ACKRC: {
    my @args = qw( --nocolor --sort-files -i nevermore t/text );

    my $ackrc = <<'HERE';
--pager=t/test-pager --skip=2
HERE

    my @expected = line_split( <<'HERE' );
t/text/raven.txt
62:    With such name as "Nevermore."
76:    Of 'Never -- nevermore.'
90:    She shall press, ah, nevermore!
104:    Quoth the Raven, "Nevermore."
118:    Quoth the Raven, "Nevermore."
HERE

    my @got = run_ack_interactive(@args, {
        ackrc => \$ackrc,
    });

    lists_match( \@got, \@expected, 'PAGER_ACKRC' );
}


PAGER_ACKRC_OVERRIDE: {
    my @args = qw( --nocolor --nopager --sort-files -i nevermore t/text );

    my $ackrc = <<'HERE';
--pager=t/test-pager --skip=2
HERE

    my @expected = line_split( <<'HERE' );
t/text/raven.txt
55:    Quoth the Raven, "Nevermore."
62:    With such name as "Nevermore."
69:    Then the bird said, "Nevermore."
76:    Of 'Never -- nevermore.'
83:    Meant in croaking "Nevermore."
90:    She shall press, ah, nevermore!
97:    Quoth the Raven, "Nevermore."
104:    Quoth the Raven, "Nevermore."
111:    Quoth the Raven, "Nevermore."
118:    Quoth the Raven, "Nevermore."
125:    Shall be lifted--nevermore!
HERE

    my @got = run_ack_interactive(@args, {
        ackrc => \$ackrc,
    });

    lists_match( \@got, \@expected, 'PAGER_ACKRC_OVERRIDE' );
}

PAGER_NOENV: {
    local $ENV{'ACK_PAGER'} = 't/test-pager --skip=2';

    my @args = qw( --nocolor --noenv --sort-files -i nevermore t/text );

    my @expected = line_split( <<'HERE' );
t/text/raven.txt
55:    Quoth the Raven, "Nevermore."
62:    With such name as "Nevermore."
69:    Then the bird said, "Nevermore."
76:    Of 'Never -- nevermore.'
83:    Meant in croaking "Nevermore."
90:    She shall press, ah, nevermore!
97:    Quoth the Raven, "Nevermore."
104:    Quoth the Raven, "Nevermore."
111:    Quoth the Raven, "Nevermore."
118:    Quoth the Raven, "Nevermore."
125:    Shall be lifted--nevermore!
HERE

    my @got = run_ack_interactive(@args);

    lists_match( \@got, \@expected, 'PAGER_NOENV' );
}


done_testing();
exit 0;
