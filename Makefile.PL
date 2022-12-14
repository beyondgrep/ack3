package main;

require 5.010001;

use strict;
use warnings;
use ExtUtils::MakeMaker;

print "Running Perl $^V at $^X\n";

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
            bugtracker  => 'https://github.com/beyondgrep/ack3',
            license     => 'https://www.perlfoundation.org/artistic-license-20.html',
            repository  => 'git://github.com/beyondgrep/ack3.git',
            MailingList => 'https://groups.google.com/group/ack-users',
        },
    },

    EXE_FILES               => [ 'ack' ],

    PREREQ_PM => {
        'Cwd'               => '3.00',
        'File::Basename'    => '1.00015',
        'File::Next'        => '1.18',
        'File::Spec'        => '3.00',
        'File::Temp'        => '0.19', # For newdir()
        'filetest'          => 0,
        'Getopt::Long'      => '2.38',
        'if'                => 0,
        'List::Util'        => 0,
        'parent'            => 0,
        'Pod::Perldoc'      => '3.20', # Starting with 3.20, default output is Pod::Perldoc::ToTerm instead of ::ToMan
        'Pod::Text'         => 0,      # Used to render pod by Pod::Usage.
        'Pod::Usage'        => '1.26',
        'Scalar::Util'      => 0,
        'Term::ANSIColor'   => '1.10',
        'Test::Harness'     => '2.50', # Something reasonably newish
        'Test::More'        => '0.98', # For subtest()
        'Text::ParseWords'  => '3.1',
        'version'           => 0,
        ( $^O eq 'MSWin32' ? ('Win32::ShellQuote' => '0.002001') : () ),
    },
    MAN3PODS            => {}, # no need for man pages for any of the .pm files
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'ack-3* nytprof* stderr.log stdout.log completion.*' },
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

TEST_VERBOSE=0
TEST_UTILS=t/*.pm
TEST_FILES=t/*.t
TEST_XT_FILES=xt/*.t

.PHONY: tags critic

tags:
	ctags -f tags --recurse --totals \
		--exclude=blib \
		--exclude=.git \
		--exclude='*~' \
		--exclude=ack-standalone \
		--exclude=garage/* \
		--exclude=ack-v3*/* \
		--languages=Perl --langmap=Perl:+.t \

# Don't run critic on docs.
critic:
	perlcritic -1 -q -profile perlcriticrc $(ACK) $(CODE_PM) $(TEST_UTILS) $(TEST_FILES) $(TEST_XT_FILES)

ack-standalone : $(ACK) $(CODE_PM) squash Makefile
	$(PERL) squash $(ACK) $(CODE_PM) File::Next %s > ack-standalone
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

test_all: test_classic test_standalone test_xt

PROF_ARGS = -Mblib blib/script/ack foo ~/parrot

nytprof: all
	$(PERL) -d:NYTProf $(PROF_ARGS) >> /dev/null 2>&1
	nytprofhtml

TIMER_ARGS=foo ~/parrot > /dev/null
time-ack196:
	time $(PERL) ./garage/ack196 --noenv $(TIMER_ARGS)

time-head: ack-standalone
	time $(PERL) ./ack-standalone --noenv $(TIMER_ARGS)

timings: ack-standalone
	./dev/timings.pl ~/parrot

timings-beta: ack-standalone
	./dev/timings.pl ~/parrot --ack=2.999_0{1,2,3,4,5,6}

completion.bash: pm_to_blib
	./dev/generate-completion-scripts.pl completion.bash

completion.zsh: pm_to_blib
	./dev/generate-completion-scripts.pl completion.zsh

MAKE_FRAG

    return $postamble;
}

1;
