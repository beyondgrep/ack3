# Tasks

* Remove all XXXes

* Figure out which App::Ack modules we actually need.

* Do we actually need to use modules?  Other than App::Ack to make CPAN updates easier?

* Get rid of the underscore methods that shouldn't be underscored.

* Design --ignore-file

* Fix behavior in `build_regex`

* Are resources just filehandles?

* Stop using eval for output.

* Put the modules in the tree properly, but add symlinks in the repo.

* Remove the App::Ack::Resource hierarchy.  Move everything in App::Ack::Resource::Basic into ::Resource.

* Rename ::Resource to ::File.

* Rename ::Resources to ::FileFactory.

* Verify underscoreness of each method/function.

* Remove the -a warning.

* Throw out App::Ack::Debug.

* Do we pass around any `$opt` hash anywhere?  Can we make everything be a global?  It will be safer.

* Rename App::Ack::Filter to something more like ::Type

* What is IsGroup.pm for?

* Import issues from ack2 into ack3.  https://github.com/IQAndreas/github-issues-import

* Remove the docs about differences from ack 1.

* Move docs into a new module App::Ack::Docs, to make it easier to work on the docs.

* Maybe even make a --faq and App::Ack::FAQ.

* Add the barfly stuff from ack2.
