#!perl

use strict;
use warnings;

use Test::More tests => 26;

use lib 't';
use Util;

prep_environment();

my @SWAMP = qw( t/swamp );

TEST_TYPE: {
    my @expected = line_split( <<'HERE' );
t/swamp/0:1:#!/usr/bin/perl -w
t/swamp/Makefile.PL:1:#!perl
t/swamp/options-crlf.pl:1:#!/usr/bin/env perl
t/swamp/options.pl:1:#!/usr/bin/env perl
t/swamp/perl-test.t:1:#!perl
t/swamp/perl-without-extension:1:#!/usr/bin/perl -w
t/swamp/perl.cgi:1:#!perl
t/swamp/perl.pl:1:#!perl
t/swamp/perl.pm:1:#!perl
HERE

    # Reslash the filenames in case we are on Windows.
    foreach ( @expected ) {
        s/^(.*?)(?=:)/reslash( $1 )/ge;
    }

    my @args    = qw( --type=perl --nogroup --noheading --nocolor );
    my @files   = @SWAMP;
    my $target  = 'perl';

    my @results = run_ack( @args, $target, @files );
    sets_match( \@results, \@expected, 'TEST_TYPE with --type=perl' );

    # Try it again with -t.
    @args    = qw( -t perl --nogroup --noheading --nocolor );
    @results = run_ack( @args, $target, @files );
    sets_match( \@results, \@expected, 'TEST_TYPE with -t perl' );

    # Try it again with --perl.
    @args    = qw( --perl --nogroup --noheading --nocolor );
    @results = run_ack( @args, $target, @files );
    sets_match( \@results, \@expected, 'TEST_TYPE with --perl' );
}

TEST_NOTYPE: {
    my @expected = line_split( <<'HERE' );
t/swamp/c-header.h:1:/*    perl.h
t/swamp/Makefile:1:# This Makefile is for the ack extension to perl.
HERE

    # Reslash the filenames in case we are on Windows.
    for ( @expected ) {
        s/^(.*?)(?=:)/reslash( $1 )/ge;
    }

    my @args    = qw( --type=noperl --nogroup --noheading --nocolor );
    my @files   = @SWAMP;
    my $target  = 'perl';

    my @results = run_ack( @args, $target, @files );
    sets_match( \@results, \@expected, 'TEST_NOTYPE with --type' );

    # Try as --noperl
    @args    = qw( --noperl --nogroup --noheading --nocolor );
    @results = run_ack( @args, $target, @files );
    sets_match( \@results, \@expected, 'TEST_NOTYPE with --noperl' );

    # Try as -t noperl
    @args    = qw( -t noperl --nogroup --noheading --nocolor );
    @results = run_ack( @args, $target, @files );
    sets_match( \@results, \@expected, 'TEST_NOTYPE with -t noperl' );


    # Try it with -T.
    @args    = qw( -T perl --nogroup --noheading --nocolor );
    @results = run_ack( @args, $target, @files );
    sets_match( \@results, \@expected, 'TEST_NOTYPE with -T' );
}

TEST_UNKNOWN_TYPE: {
    my @args   = qw( --ignore-ack-defaults --type-add=perl:ext:pl --type=foo --nogroup --noheading --nocolor );
    my @files   = @SWAMP;
    my $target = 'perl';

    my ( $stdout, $stderr ) = run_ack_with_stderr( @args, $target, @files );

    is_empty_array( $stdout, 'Should have no lines back' );
    first_line_like( $stderr, qr/Unknown type 'foo'/ );
}

TEST_NOTYPES: {
    my @args   = qw( --ignore-ack-defaults --type=perl --nogroup --noheading --nocolor );
    my @files  = @SWAMP;
    my $target = 'perl';

    my ( $stdout, $stderr ) = run_ack_with_stderr( @args, $target, @files );

    is_empty_array( $stdout, 'Should have no lines back' );
    first_line_like( $stderr, qr/Unknown type 'perl'/ );
}

TEST_NOTYPE_OVERRIDE: {
    my @expected = (
        reslash('t/swamp/html.htm') . ':2:<html><head><title>Boring test file </title></head>',
        reslash('t/swamp/html.html') . ':2:<html><head><title>Boring test file </title></head>',
    );

    my @lines = run_ack( '--nohtml', '--html', '--sort-files', '<title>', @SWAMP );
    is_deeply( \@lines, \@expected );
}

TEST_TYPE_OVERRIDE: {
    my @lines = run_ack( '--html', '--nohtml', '<title>', @SWAMP );
    is_empty_array( \@lines );
}

TEST_NOTYPE_ACKRC_CMD_LINE_OVERRIDE: {
    my $ackrc = <<'HERE';
--nohtml
HERE

    my @expected = (
        reslash('t/swamp/html.htm') . ':2:<html><head><title>Boring test file </title></head>',
        reslash('t/swamp/html.html') . ':2:<html><head><title>Boring test file </title></head>',
    );

    my @lines = run_ack('--html', '--sort-files', '<title>', @SWAMP, {
        ackrc => \$ackrc,
    });
    is_deeply( \@lines, \@expected );
}

TEST_TYPE_ACKRC_CMD_LINE_OVERRIDE: {
    my $ackrc = <<'HERE';
--html
HERE

    my @expected;

    my @lines = run_ack('--nohtml', '<title>', @SWAMP, {
        ackrc => \$ackrc,
    });
    is_deeply( \@lines, \@expected );
}

done_testing();
exit 0;
