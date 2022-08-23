#!/usr/bin/perl

use warnings;
use strict;
use 5.010;

use Test::More tests => 2;

use App::Ack;

my $lc_list = <<'END'; ## no critic ( CodeLayout::RequireASCII )
select . from table
select \S+ from table
select [^\s]+ from table

# Character specifications
find a tab -> \x09
"foo" in hex -> \x66\x6f\x6f with lowercase digits
"foo" in hex -> \x66\x6F\x6F with uppercase digits
control sequences: ctrl-x=\cX
# unicode sequences: \N{GRAVE ACCENT}
unicode sequences: \N{U+263D}
ladies and gentlemen, please welcome, ❤️!

# Regex metacharacters
keep stuff to the left -> \K
non-word character -> \W
non-space character -> \S
non-digit character -> \D
something something \X
not vertical whitespace -> \V
not horizontal whitespace -> \H
linebreak -> \R

# unicode regex metachars
# https://www.regular-expressions.info/unicode.html
named property -> \p{Word} same as \w
not the named property -> \P{Word} same as \W
single-character named property shorthand -> \pL is any letter
negation of single-character named property shorthand -> \PL is not any letter

# Not sure about \X
big combination: \W\S\D\V\H\R but still lowercase

# Zero-width assertions
not a word boundary -> \B
beginning of a string -> \A
end of a string -> \Z
end-of-match position of prior match -> \G

# Captures
named capture group and backref -> (?'NAME'pattern) \k'NAME'
named capture group and backref -> (?<NAME>pattern) \k<NAME>
# Weird combinations
\A\B\S{14}\G\Dfoo\W*\S+\Z
END


my $uc_list = <<'END';
This is \\Here.
foo[A-Z]+
[A-Z]*bar
parens([A-Z]*)
foo(?!lookahead)([A-Z]*)

# Don't get confused by regex metacharacters.
\WWhat now?
dumb \DDonald
lost in \SSpace
lost in \\\\Diskland

# Weird combinations
\A\\\B\S{14}\G\\\D\\Dog\\\W*\\\\\S+\\\\\Z
\\W//\\W//\\Larry//\\D//?
END


my @lc_list = _big_split($lc_list);
if ( $] >= 5.012 ) {
    push( @lc_list, 'anything but \n -> \N' );
}

my @uc_list = _big_split($uc_list);

subtest 'Check lowercase' => sub {
    plan tests => scalar @lc_list;

    for my $lc ( @lc_list ) {
        my $re = qr/$lc/;
        ok( App::Ack::is_lowercase( $lc ), qq{"$lc" should be lowercase} );
    }
};

subtest 'Check uppercase' => sub {
    plan tests => scalar @uc_list;

    for my $uc ( @uc_list ) {
        my $re = qr/$uc/;
        ok( !App::Ack::is_lowercase( $uc ), qq{"$uc" should not be lowercase} );
    }
};

done_testing();
exit 0;


sub _big_split {
    my $str = shift;

    return grep { /./ && !/^#/ } split( /\n/, $str );
}
