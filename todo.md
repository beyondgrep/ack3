# Infrastructure tasks for `2.999_01`

* Add the barfly stuff from ack2.

* Make a test file to test all the libs to replace t/lib/

* Remove all XXXes

* Make constructions in GitHub

# Documentation tasks

* Remove the docs about differences from ack 1.

* Move docs into a new module App::Ack::Docs, to make it easier to work on the docs.

* Update DEVELOPERS.md

* Maybe even make a --faq and App::Ack::FAQ.

# Functionality tasks

* Design `--ignore-file`

* Fix behavior in `build_regex`

* Stop using eval for output.

* Remove the -a warning.

* Do we pass around any `$opt` hash anywhere?  Can we make everything be a global?  It will be safer.

* Import issues from ack2 into ack3.  https://github.com/IQAndreas/github-issues-import
