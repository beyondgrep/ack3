# Build status of dev branch

* Linux [![Build Status](https://travis-ci.org/beyondgrep/ack3.png?branch=dev)](https://travis-ci.org/beyondgrep/ack3)
* Windows [![Build Status](https://ci.appveyor.com/api/projects/status/github/beyondgrep/ack3)](https://ci.appveyor.com/project/petdance/ack3)
* [CPAN Testers](https://cpantesters.org/distro/A/ack.html)

# ack 3

ack is a code-searching tool, similar to grep but optimized for
programmers searching large trees of source code.  It is highly
portable and runs on any platform that runs Perl.

ack is written and maintained by Andy Lester (andy@petdance.com).

* [Project home page](https://beyondgrep.com/)
* [Code home page](https://github.com/beyondgrep/ack3)
* [Issue tracker](https://github.com/beyondgrep/ack3/issues)
* Mailing lists
    * [Announcements](https://groups.google.com/d/forum/ack-announcements)
    * [Users](https://groups.google.com/d/forum/ack-users)
    * [Developers](https://groups.google.com/d/forum/ack-dev)

# Building

ack requires Perl 5.10.1 or higher, and it requires the
[File::Next](https://metacpan.org/pod/File::Next) module to be installed.

## Checking prerequisites

To check ack's dependencies, run this command in the shell:

    perl -MFile::Next -E'say "ack is ready to build!"'

If everything is OK, you'll see:

    ack is ready to build!

If your installation of Perl is outdated, you'll see an error like this:

    Unrecognized switch: -Esay "ack is ready to build!"  (-h will show valid options).

If you don't have File::Next installed, you'll see an error like this:

    Can't locate File/Next.pm in @INC (@INC contains: /home/andy/...
    BEGIN failed--compilation aborted.

and you'll need to install File::Next yourself:

    # Install File::Next dependency
    perl -MCPAN -e install File::Next

## Building ack

If you've got a recent enough version of Perl and you have File::Next
installed, you can build ack.

    # Required
    perl Makefile.PL
    make
    make test
    sudo make install # For a system-wide installation
    # - or -
    make ack-standalone
    cp ack-standalone ~/bin/ack3 # For a personal installation

# Development

* [How to contribute](CONTRIBUTING.md)
* [Developer's Guide](DEVELOPERS.md)
* [Design Guide](DESIGN.md)

# Community

See the [Community](https://beyondgrep.com/community/) page.

# License

Copyright 2005-2019 Andy Lester.

This program is free software; you can redistribute it and/or modify
it under the terms of the
[Artistic License v2.0](https://www.perlfoundation.org/artistic_license_2_0).
See also the LICENSE.md file that comes with the ack distribution.
