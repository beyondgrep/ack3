# Validate with cpanfile-dump
# https://metacpan.org/release/Module-CPANfile
# https://metacpan.org/pod/distribution/Module-CPANfile/lib/cpanfile.pod

requires 'Cwd'              => '3.00';
requires 'File::Basename'   => '1.00015';
requires 'File::Next'       => '1.18';
requires 'File::Spec'       => '3.00';
requires 'Getopt::Long'     => '2.38';
requires 'if'               => 0;
requires 'List::Util'       => 0;
requires 'parent'           => 0;
requires 'Pod::Perldoc'     => '3.20'; # Starting with 3.20, default output is Pod::Perldoc::ToTerm instead of ::ToMan
requires 'Pod::Text'        => 0;      # Used to render pod by Pod::Usage.
requires 'Pod::Usage'       => '1.26';
requires 'Term::ANSIColor'  => '1.10';
requires 'Text::ParseWords' => '3.1';
requires 'version'          => 0;

if ( $^O eq 'MSWin32' ) {
    requires 'Win32::ShellQuote' => '0.002001';
}

on 'test' => sub {
    requires 'File::Temp'    => '0.19', # For newdir()
    requires 'Scalar::Util'  => 0;
    requires 'Test::Harness' => '2.50'; # Something reasonably newish
    requires 'Test::More'    => '0.98'; # For subtest()

    if ( $^O ne 'MSWin32' ) {
        requires 'IO::Pty' => 0;
    }
};

# vi:et:sw=4 ts=4 ft=perl
