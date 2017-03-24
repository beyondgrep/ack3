# Tasks for 2.18

* All modules must have proper POD.

# Tasks for start of ack3 codebase.

# Tasks for `2.999_01`

* Remove all XXXes

* Get rid of the underscore methods that shouldn't be underscored.

* Design --ignore-file

* Fix behavior in `build_regex`

* Are resources just filehandles?

* Stop using eval for output.

* Put the modules in the tree properly, but add symlinks in the repo.

* Rename ::Resource to ::File.

* Rename ::Resources to ::FileFactory.

* Verify underscoreness of each method/function.

* Remove the -a warning.

* Do we pass around any `$opt` hash anywhere?  Can we make everything be a global?  It will be safer.

* Rename App::Ack::Filter to something more like ::Type

* Import issues from ack2 into ack3.  https://github.com/IQAndreas/github-issues-import

* Remove the docs about differences from ack 1.

* Move docs into a new module App::Ack::Docs, to make it easier to work on the docs.

* Update DEVELOPERS.md

* Maybe even make a --faq and App::Ack::FAQ.

* Add the barfly stuff from ack2.
