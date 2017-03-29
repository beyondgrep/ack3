# Release notes for ack 3.000

# New features

ack 3 is a greplike tool optimized for searching large code trees.

Improvements over ack 2 include:

* Improved `-w` function.


# Incompatibilities with ack 2

## ack 3 no longer highlights capture groups.

ack 2 would highlight your capture groups.  For example,

    ack '(set|get)_foo_(name|id)'

would highlight the `set` or `get`, and the `name` or `id`, but not the
full `set_user_id`.

This feature has been removed.

## Removed unused filetypes
