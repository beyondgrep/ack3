# Release notes for ack 3.000

# New features

ack 3 is a greplike tool optimized for searching large code trees.

Improvements over ack 2 include:

* Improved `-w` means more accurate searching for words.

* `-w` option will warn if your pattern does not lend itself to
word matching.

* `-i`, `-I` and `--smart-case`

* `--proximate=N` option

* Added `--pod` and `--markdown`.

* Added `GNUmakefile` to the list of makefile specs.

* Added `-S` as a synonym for `--smart-case`.

# Bug fixes

* Column numbers were not getting colorized in the output.  Added
`--color-colno` option and `ACK_COLOR_COLNO` environment variable.

* A pattern that wanted whitespace at the end could match the
linefeed at the end of a line.  This is no longer possible.

# Incompatibilities with ack 2

## ack 3 requires Perl 5.10.1

ack 2 only needed Perl 5.8.8.  This shouldn't be a problem since 5.10.1
has been out since 2009.

## -w is fussier

ack 3 will not allow you to use `-w` with a pattern that doesn't begin or
end with a word character.

## ack 3 no longer highlights capture groups.

ack 2 would highlight your capture groups.  For example,

    ack '(set|get)_foo_(name|id)'

would highlight the `set` or `get`, and the `name` or `id`, but not the
full `set_user_id` that was matched.

This feature was too confusing and has been removed.  Now, the entire
matching string is highlighted.

## ack 3's --output allows fewer special variables

In ack 2, you could put any kind of Perl code in the `--output`
option and it would get `eval`uated at run time, which would let
you do tricky stuff like this gem from Mark Fowler
(http://www.perladvent.org/2014/2014-12-21.html):

    ack --output='$&: @{[ eval "use LWP::Simple; 1" && length LWP::Simple::get($&) ]} bytes' \
                    'https?://\S+' list.txt
    http://google.com/: 19529 bytes
    http://metacpan.org/: 7560 bytes
    http://www.perladvent.org/: 5562 bytes

This has been a security problem in the past, and so in ack 3 we
no longer `eval` the contents of `--output`.  You're now restricted
to the following variables: `$1` thru `$9`, `$_`, `$.`, `$&`, ``$` ``,
`$'` and `$+`.  You can also embed `\t`, `\n` and `\r` ,
and `$f` as stand-in for `$filename` in `ack2 --output` .

## ack 3 no longer uses the `ACK_OPTIONS` environment variable

The `ACK_OPTIONS` variable was used to supply command line arguments to
ack invocations.  This has been removed.  Use an ackrc file instead.
