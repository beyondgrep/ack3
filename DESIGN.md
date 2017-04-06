# ack3 design

Here we try to document ack's design, including design decisions
that have already been made, so that we don't keep rehashing them.

# Features that have been suggested but will not happen.

* ack will not do replacing of text.  It is not a replacement for sed.

* ack will not edit files or invoke editors.

* ack will not sort files by default.

Sorting the filenames requires reading in the entire directory of
filenames before searching, and this can be a performance hit.  In fact,
it can kill ack entirely on directories with absurdly large numbers of
files in them.

# Design choices that are inviolate.

* ack must run purely as Perl 5.10.1 using only core modules and File::Next.

No other modules may be used.  That includes Moose.

* We don't use the Perl smartmatch operator.

* ack must be able to be distributed through CPAN, using the App::Ack:: module tree.

* ack must be able to be built as a single-file standalone file.

This file is intended to be able to be copied & pasted if necessary.
It will not contain any characters out the range of `[ -~]`.
See `xt/coding-standards.t`.

* ack must be cross-platform.  Specifically, it must run on Windows.

* ack must not use any external tools.

* The detection of whether a file is text or not is decided by Perl's `-T` operator.

* Filetype detection is only through user-defined rules.  ack will not
shell out to `file` or any similar utilities.

* ack must be able to be run under taint mode.

* Use Perl's default file-handling as far as dealing with files of
different encodings

* ack must be able to be configured entirely from the command-line.
ackrc files are merely collections of command-line switches.


# Design questions that have been investigated

* Would ack be faster if we used the integer pragma?

It seems not.  Brian M. Carlson investigated this and reported his
findings here: https://github.com/petdance/ack2/issues/398

There seemed to be no effect.

* Why not make ack use /usr/bin/env in the shebang instead of /usr/bin/perl?

The Perl toolchain takes care of the shebang at install time.

# Guiding principles

* When deciding on ack's behavior, try to be grep-compatible if possible.
