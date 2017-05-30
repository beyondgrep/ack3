# Release notes for ack 3.000

# New features

ack 3 is a greplike tool optimized for searching large code trees.

Improvements over ack 2 include:

* Improved `-w` option.

* `-w` option will warn if your pattern does not lend itself to
word matching.

* `-i`, `-I` and `--smart-case`

* `--proximate=N` option

* Added `--pod` and `--markdown`.

# Incompatibilities with ack 2

## ack 3 requires Perl 5.10.1

ack 2 only needed Perl 5.8.8.  This shouldn't be a problem since 5.10.1
has been out since 2009.

## ack 3 no longer highlights capture groups.

ack 2 would highlight your capture groups.  For example,

    ack '(set|get)_foo_(name|id)'

would highlight the `set` or `get`, and the `name` or `id`, but not the
full `set_user_id` that was matched.

This feature was too confusing and has been removed.  Now, the entire
matching string is highlighted.
