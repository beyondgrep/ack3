* Rewriting how `-w` works.

* Fixing how match highlighting works.

* New `--underline` option for highlighting via text, not color.

* New semantics on `--ignore-file` and `--ignore-directory`

* Fix line counting

* Add feature to group consecutive lines: the clumping feature

# Minor changes

* Allow --output and --regex only on the command line, not in an ackrc (ack2 GH #414)

* -I for --no-smart-case

* --auto-spacing that replaces any whitespace in the pattern with \w+, so "insert into table" becomes "insert\s+into\s+table".

* Add flag to force line number on output.

* `--output` will be redone to be safe.
