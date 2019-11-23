#!perl

use warnings;
use strict;

use Test::More tests => 3;

use lib 't';
use Util;

prep_environment();

subtest 'No restrictions on type' => sub {
    my $expected = <<'HERE';
t/etc/buttonhook.xml.xxx => xml
t/etc/shebang.empty.xxx =>
t/etc/shebang.foobar.xxx =>
t/etc/shebang.php.xxx => php
t/etc/shebang.pl.xxx => perl
t/etc/shebang.py.xxx => python
t/etc/shebang.rb.xxx => ruby
t/etc/shebang.sh.xxx => shell
HERE
    my @expected = reslash_all( line_split( $expected ) );

    my @args = qw( -f --show-types t/etc );
    ack_sets_match( [ @args ], \@expected, 'No restrictions on type' );
};

subtest 'Only known types' => sub {
    my $expected = <<'HERE';
t/etc/buttonhook.xml.xxx => xml
t/etc/shebang.php.xxx => php
t/etc/shebang.pl.xxx => perl
t/etc/shebang.py.xxx => python
t/etc/shebang.rb.xxx => ruby
t/etc/shebang.sh.xxx => shell
HERE
    my @expected = reslash_all( line_split( $expected ) );

    my @args = qw( -f -k --show-types t/etc );
    ack_sets_match( [ @args ], \@expected, 'Only known types' );
};


subtest 'More testing' => sub {
    plan tests => 4;

    my @files = qw(
        t/swamp/0
        t/swamp/constitution-100k.pl
        t/swamp/Rakefile
        t/swamp/options-crlf.pl
        t/swamp/options.pl
        t/swamp/javascript.js
        t/swamp/html.html
        t/swamp/perl-without-extension
        t/swamp/sample.rake
        t/swamp/perl.cgi
        t/swamp/Makefile
        t/swamp/pipe-stress-freaks.F
        t/swamp/perl.pod
        t/swamp/html.htm
        t/swamp/perl-test.t
        t/swamp/perl.handler.pod
        t/swamp/perl.pl
        t/swamp/Makefile.PL
        t/swamp/MasterPage.master
        t/swamp/c-source.c
        t/swamp/perl.pm
        t/swamp/c-header.h
        t/swamp/crystallography-weenies.f
        t/swamp/CMakeLists.txt
        t/swamp/Sample.ascx
        t/swamp/Sample.asmx
        t/swamp/sample.asp
        t/swamp/sample.aspx
        t/swamp/service.svc
        t/swamp/stuff.cmake
        t/swamp/example.R
        t/swamp/fresh.css
        t/swamp/lua-shebang-test
        t/swamp/notes.md
    );

    my @files_no_perl = qw(
        t/swamp/Rakefile
        t/swamp/javascript.js
        t/swamp/html.html
        t/swamp/sample.rake
        t/swamp/Makefile
        t/swamp/MasterPage.master
        t/swamp/pipe-stress-freaks.F
        t/swamp/html.htm
        t/swamp/c-source.c
        t/swamp/c-header.h
        t/swamp/crystallography-weenies.f
        t/swamp/CMakeLists.txt
        t/swamp/Sample.ascx
        t/swamp/Sample.asmx
        t/swamp/sample.asp
        t/swamp/sample.aspx
        t/swamp/service.svc
        t/swamp/stuff.cmake
        t/swamp/example.R
        t/swamp/fresh.css
        t/swamp/lua-shebang-test
        t/swamp/notes.md
    );


    for my $k_arg ( '-k', '--known-types' ) {
        ack_sets_match( [ $k_arg, '-f', 't/swamp' ], \@files, "$k_arg test #1" );
        ack_sets_match( [ $k_arg, '-T', 'perl', '-f', 't/swamp' ], \@files_no_perl, "$k_arg test #2" );
    }
};

done_testing();

exit 0;
