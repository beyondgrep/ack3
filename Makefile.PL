package main;

require 5.010001;

use strict;
use warnings;
use ExtUtils::MakeMaker;

my $debug_mode = (grep { $_ eq '--debug' } @ARGV) ? '--debug' : '';

my %parms = (
    NAME                => 'ack',
    AUTHOR              => 'Andy Lester <andy@petdance.com>',
    ABSTRACT            => 'A grep-like program for searching source code',
    VERSION_FROM        => 'lib/App/Ack.pm',
    LICENSE             => 'artistic_2',
    MIN_PERL_VERSION    => 5.010001,
    META_MERGE          => {
        resources => {
            homepage    => 'https://beyondgrep.com/',
            bugtracker  => 'https://github.com/petdance/ack3',
            license     => 'http://www.perlfoundation.org/artistic_license_2_0',
            repository  => 'git://github.com/petdance/ack3.git',
            MailingList => 'https://groups.google.com/group/ack-users',
        },
    },

    EXE_FILES               => [ 'ack' ],

    PREREQ_PM => {
        'Carp'              => '1.04',
        'Cwd'               => '3.00',
        'Errno'             => 0,
        'File::Basename'    => '1.00015',
        'File::Next'        => '1.16',
        'File::Spec'        => '3.00',
        'File::Temp'        => '0.19', # For newdir()
        'if'                => 0,
        'Getopt::Long'      => '2.38',
        'parent'            => 0,
        'Pod::Usage'        => '1.26',
        'Scalar::Util'      => 0,
        'Term::ANSIColor'   => '1.10',
        'Test::Harness'     => '2.50', # Something reasonably newish
        'Test::More'        => '0.98', # For subtest()
        'Text::ParseWords'  => '3.1',
        ( $^O eq 'MSWin32' ? ('Win32::ShellQuote' => '0.002001') : () ),
    },
    MAN3PODS            => {}, # no need for man pages for any of the .pm files
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'ack-2* nytprof* stderr.log stdout.log completion.*' },
);

WriteMakefile( %parms );

package MY;

# Suppress EU::MM test rule.
sub MY::test {
    return '';
}

sub MY::postamble {
    my $postamble = sprintf(<<'MAKE_FRAG', $debug_mode);
ACK    = ack
CODE_PM = \
    lib/App/Ack.pm \
    \
    lib/App/Ack/ConfigDefault.pm \
    lib/App/Ack/ConfigFinder.pm \
    lib/App/Ack/ConfigLoader.pm \
    lib/App/Ack/File.pm \
    lib/App/Ack/Files.pm \
    lib/App/Ack/Filter.pm \
    \
    lib/App/Ack/Filter/Collection.pm \
    lib/App/Ack/Filter/Default.pm \
    lib/App/Ack/Filter/Extension.pm \
    lib/App/Ack/Filter/ExtensionGroup.pm \
    lib/App/Ack/Filter/FirstLineMatch.pm \
    lib/App/Ack/Filter/Inverse.pm \
    lib/App/Ack/Filter/Is.pm \
    lib/App/Ack/Filter/IsGroup.pm \
    lib/App/Ack/Filter/IsPath.pm \
    lib/App/Ack/Filter/IsPathGroup.pm \
    lib/App/Ack/Filter/Match.pm \
    lib/App/Ack/Filter/MatchGroup.pm \

DOCS_PM = \
    lib/App/Ack/Docs/Manual.pm \
    lib/App/Ack/Docs/FAQ.pm \
    lib/App/Ack/Docs/Cookbook.pm \

TEST_VERBOSE=0
TEST_FILES=t/*.t
TEST_XT_FILES=xt/*.t

.PHONY: tags critic

tags:
	ctags -f tags --recurse --totals \
		--exclude=blib \
		--exclude=.git \
		--exclude='*~' \
		--exclude=ack-standalone \
		--languages=Perl --langmap=Perl:+.t \

# Don't run critic on docs.
critic:
	perlcritic -1 -q -profile perlcriticrc $(ACK) $(CODE_PM) $(TEST_FILES) $(TEST_XT_FILES)

ack-standalone : $(ACK) $(CODE_PM) $(DOCS_PM) squash Makefile
	$(PERL) squash $(ACK) $(CODE_PM) File::Next $(DOCS_PM) %s > ack-standalone
	$(FIXIN) ack-standalone
	-$(NOECHO) $(CHMOD) $(PERM_RWX) ack-standalone
	$(PERL) -c ack-standalone

bininst : $(ACK)
	$(CP) $(ACK) ~/bin/ack3
	$(CP) ackrc ~/.ack3rc

test: test_classic test_standalone

fulltest: test_classic test_standalone test_xt

test_classic: all
	$(FULLPERLRUN) t/runtests.pl 0 $(TEST_VERBOSE) "$(INST_LIB)" "$(INST_ARCHLIB)" $(TEST_FILES)

test_standalone: all ack-standalone
	$(FULLPERLRUN) t/runtests.pl 1 $(TEST_VERBOSE) "$(INST_LIB)" "$(INST_ARCHLIB)" $(TEST_FILES)

test_xt: all
	$(FULLPERLRUN) t/runtests.pl 0 $(TEST_VERBOSE) "$(INST_LIB)" "$(INST_ARCHLIB)" $(TEST_XT_FILES)

PROF_ARGS = -Mblib blib/script/ack foo ~/parrot

nytprof: all
	$(PERL) -d:NYTProf $(PROF_ARGS) >> /dev/null 2>&1
	nytprofhtml

TIMER_ARGS=foo ~/parrot > /dev/null
time-ack196:
	time $(PERL) ./garage/ack196 --noenv $(TIMER_ARGS)

time-ack202:
	time $(PERL) ./garage/ack202 --noenv $(TIMER_ARGS)

time-ack20301:
	time $(PERL) ./garage/ack20301 --noenv $(TIMER_ARGS)

time-ack20302:
	time $(PERL) ./garage/ack20302 --noenv $(TIMER_ARGS)

time-head: ack-standalone
	time $(PERL) ./ack-standalone --noenv $(TIMER_ARGS)

timings: ack-standalone
	./dev/timings.pl

completion.bash: pm_to_blib
	./dev/generate-completion-scripts.pl completion.bash

completion.zsh: pm_to_blib
	./dev/generate-completion-scripts.pl completion.zsh

MAKE_FRAG

    return $postamble;
}

1;
