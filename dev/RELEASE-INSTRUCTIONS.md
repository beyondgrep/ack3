# How to make a release of ack

## Update all the code

* Update the version number in `ack` and `lib/App/Ack.pm`

* Update copyright year if necessary.

* Make sure `Changes.pod` is up-to-date and has a version number in the top.

* Make a clean build and test the distro:

    perl Makefile.PL
    make disttest

* Push to GitHub to force a check of the branch.
    * Check the status
    * https://ci.appveyor.com/project/petdance/ack3
    * https://travis-ci.org/beyondgrep/ack3

## Make a release

* Merge to master and build

```
git co master
git merge dev
perl Makefile.PL
make tardist
```

* Upload the tarball to PAUSE

* Copy to garage

```
make ack-standalone
mv ack-standalone garage/ack-v3.x.y
git add garage/ack-v3.x.y
git commit -m'Added 3.x.y to the garage'
```

## Update the website

This is all in the beyondgrep/website project.

* Copy the ack-standalone and changelog

```
cd ~/website
cp ~/ack3/ack-standalone static/ack-v3.x.y
cp ~/ack3/Changes static/changes.txt
```

* Update version in `crank`

* Update version and date in `tt/vars.tt`.

* Regenerate the help text

```
perl static/ack-v3.x.y > tt/ack-help.txt
```

* Regenerate the help types

```
perl static/ack-v3.x.y --help-types > tt/ack-help-types.txt
```

* Regenerate the HTML help page

```
pod2html static/ack-v3.x.y > static/documentation/ack-v3.x.y-man.html
```

* ack for the old version number just to be sure there aren't others.

* Make and install

```
make
make test
make rsync
```

* Commit all changes. Some files will be updated, and some will be new.


## GitHub cleanup

* Close the milestone in GitHub

* Create a new milestone in GitHub for the next version
