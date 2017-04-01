# --ignore-dir and --ignore-file revamp

Users have been dissatisfied with `--ignore-dir` and `--ignore-file`.  Here are some common "bug reports"

  - `--ignore-dir=foo/bar` doesn't ignore `foo/bar` at all (GH ack2#291)
  - `--ignore-dir=foo` ignores all directories named `foo`, not just the one at the root of the search (GH ack2#216)
  - `--ignore-dir=foo foo -f` doesn't search `foo/` (GH ack2#492)
  - No way to ignore a file in a folder (GH ack2#479)
  - `--ignore-dir` doesn't implement all filters (GH ack2#42)
  - What's the right behavior for `--ignore-dir=foo`, `--noignore-dir=bar`, `--ignore-dir=baz`, wrt. `foo/bar/baz/file.txt`

Also consider GH ack2#330, and consider that you could be anywhere in a
project but still source the `--ignore-dir=./foo` rule from an ackrc a
few directories above.  Are we preparing to teach ack about the notion
of a project root?  Also, consider `--noignore-dir`

# Future directions

## Scenario 1

--ignore-dir can ignore paths as well as directories.  But then relative
to what?  Current directory?  That means an --ignore-dir in an .ackrc
isn't useful.

Do we make the relativeness based on where the directive is?  Is an
--ignore-dir in a project-level .ackrc relative to that file?  And an
--ignore-dir from the command-line is relative to Cwd?

## Scenario 2

`--ignore-dir` only ignores directories, but warns if you try to ignore a path

What's the distinction between `--ignore-file` and
`--type`/`--notype`?  Does it make sense to allow an "anonymous" type (ex.
`--type=is:Something`), and make `--ignore-file` a synonym for `--notype`?
Could `--ignore-dir` be implemented like this?

If I have `--ignore-dir=test` in my .ackrc, and I do `ack $term test`, what happens?
