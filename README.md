# Build status of dev branch

* Linux [![Build Status](https://travis-ci.org/beyondgrep/ack3.png?branch=dev)](https://travis-ci.org/beyondgrep/ack3)
* Windows [![Build Status](https://ci.appveyor.com/api/projects/status/github/beyondgrep/ack3)](https://ci.appveyor.com/project/petdance/ack3)
* [CPAN Testers](https://cpantesters.org/distro/A/ack.html)

# ack 3

ack is a code-searching tool, similar to grep but optimized for
programmers searching large trees of source code.  It is highly
portable and runs on any platform that runs Perl.

ack is written and maintained by Andy Lester (andy@beyondgrep.com).

* [Project home page](https://beyondgrep.com/)
* [Code home page](https://github.com/beyondgrep/ack3)
* [Issue tracker](https://github.com/beyondgrep/ack3/issues)
* Mailing lists
    * [Announcements](https://groups.google.com/d/forum/ack-announcements)
    * [Users](https://groups.google.com/d/forum/ack-users)
    * [Developers](https://groups.google.com/d/forum/ack-dev)

# Building

ack requires Perl 5.10.1 or higher. Perl 5.10.1 was released August 2009.

ack is dependent on the [File::Next](https://github.com/karenetheridge/File-Next) module which will have to be installed before building.

    # Install File::Next dependency
    perl -MCPAN -e install File::Next
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
