package App::Ack::ConfigDefault;

use warnings;
use strict;

use App::Ack ();


=head1 NAME

App::Ack::ConfigDefault

=head1 DESCRIPTION

A module that contains the default configuration for ack.

=cut

sub options {
    return split( /\n/, _options_block() );
}


sub options_clean {
    return grep { /./ && !/^#/ } options();
}


sub _options_block {
    my $lines = <<'HERE';
# This is the default ackrc for ack version ==VERSION==.

# There are four different ways to match
#
# is:  Match the filename exactly
#
# ext: Match the extension of the filename exactly
#
# match: Match the filename against a Perl regular expression
#
# firstlinematch: Match the first 250 characters of the first line
#   of text against a Perl regular expression.  This is only for
#   the --type-add option.


### Directories to ignore

# Bazaar
# https://bazaar.canonical.com/
--ignore-directory=is:.bzr

# Codeville
# http://freshmeat.sourceforge.net/projects/codeville
--ignore-directory=is:.cdv

# Interface Builder (Xcode)
# https://en.wikipedia.org/wiki/Interface_Builder
--ignore-directory=is:~.dep
--ignore-directory=is:~.dot
--ignore-directory=is:~.nib
--ignore-directory=is:~.plst

# Git
# https://git-scm.com/
--ignore-directory=is:.git
# When submodules are used, .git is a file.
--ignore-file=is:.git

# Mercurial
# https://www.mercurial-scm.org/
--ignore-directory=is:.hg

# Quilt
# https://directory.fsf.org/wiki/Quilt
--ignore-directory=is:.pc

# Subversion
# https://subversion.apache.org/
--ignore-directory=is:.svn

# Monotone
# https://www.monotone.ca/
--ignore-directory=is:_MTN

# CVS
# https://savannah.nongnu.org/projects/cvs
--ignore-directory=is:CVS

# RCS
# https://www.gnu.org/software/rcs/
--ignore-directory=is:RCS

# SCCS
# https://en.wikipedia.org/wiki/Source_Code_Control_System
--ignore-directory=is:SCCS

# darcs
# http://darcs.net/
--ignore-directory=is:_darcs

# Vault/Fortress
--ignore-directory=is:_sgbak

# autoconf
# https://www.gnu.org/software/autoconf/
--ignore-directory=is:autom4te.cache

# Perl module building
--ignore-directory=is:blib
--ignore-directory=is:_build

# Perl Devel::Cover module's output directory
# https://metacpan.org/release/Devel-Cover
--ignore-directory=is:cover_db

# Node modules created by npm
--ignore-directory=is:node_modules

# CMake cache
# https://www.cmake.org/
--ignore-directory=is:CMakeFiles

# Eclipse workspace folder
# https://eclipse.org/
--ignore-directory=is:.metadata

# Cabal (Haskell) sandboxes
# https://www.haskell.org/cabal/users-guide/installing-packages.html
--ignore-directory=is:.cabal-sandbox

# Python caches
# https://docs.python.org/3/tutorial/modules.html
--ignore-directory=is:__pycache__
--ignore-directory=is:.pytest_cache

# macOS Finder remnants
--ignore-directory=is:__MACOSX
--ignore-file=is:.DS_Store

### Files to ignore

# Backup files
--ignore-file=ext:bak
--ignore-file=match:/~$/

# Emacs swap files
--ignore-file=match:/^#.+#$/

# vi/vim swap files https://www.vim.org/
--ignore-file=match:/[._].*[.]swp$/

# core dumps
--ignore-file=match:/core[.]\d+$/

# minified JavaScript
--ignore-file=match:/[.-]min[.]js$/
--ignore-file=match:/[.]js[.]min$/

# minified CSS
--ignore-file=match:/[.]min[.]css$/
--ignore-file=match:/[.]css[.]min$/

# JS and CSS source maps
--ignore-file=match:/[.]js[.]map$/
--ignore-file=match:/[.]css[.]map$/

# PDFs, because they pass Perl's -T detection
--ignore-file=ext:pdf

# Common graphics, just as an optimization
--ignore-file=ext:gif,jpg,jpeg,png

# Common archives, as an optimization
--ignore-file=ext:gz,tar,tgz,zip

# Python compiled modules
--ignore-file=ext:pyc,pyd,pyo

# Python's pickle serialization format
# https://docs.python.org/2/library/pickle.html#example
# https://docs.python.org/3.7/library/pickle.html#examples
--ignore-file=ext:pkl,pickle

# C extensions
--ignore-file=ext:so

# Compiled gettext files
--ignore-file=ext:mo

# Visual Studio user and workspace settings
# https://code.visualstudio.com/docs/getstarted/settings
--ignore-dir=is:.vscode

### Filetypes defined

# Makefiles
# https://www.gnu.org/s/make/
--type-add=make:ext:mk
--type-add=make:ext:mak
--type-add=make:is:makefile
--type-add=make:is:Makefile
--type-add=make:is:Makefile.Debug
--type-add=make:is:Makefile.Release
--type-add=make:is:GNUmakefile

# Rakefiles
# https://rake.rubyforge.org/
--type-add=rake:is:Rakefile

# CMake
# https://cmake.org/
--type-add=cmake:is:CMakeLists.txt
--type-add=cmake:ext:cmake

# Bazel build tool
# https://docs.bazel.build/versions/master/skylark/bzl-style.html
--type-add=bazel:ext:bzl
# https://docs.bazel.build/versions/master/guide.html#bazelrc-the-bazel-configuration-file
--type-add=bazel:ext:bazelrc
# https://docs.bazel.build/versions/master/build-ref.html#BUILD_files
--type-add=bazel:is:BUILD
# https://docs.bazel.build/versions/master/build-ref.html#workspace
--type-add=bazel:is:WORKSPACE


# Actionscript
--type-add=actionscript:ext:as,mxml

# Ada
# https://www.adaic.org/
--type-add=ada:ext:ada,adb,ads

# ASP
# https://docs.microsoft.com/en-us/previous-versions/office/developer/server-technologies/aa286483(v=msdn.10)
--type-add=asp:ext:asp

# ASP.Net
# https://dotnet.microsoft.com/apps/aspnet
--type-add=aspx:ext:master,ascx,asmx,aspx,svc

# Assembly
--type-add=asm:ext:asm,s

# DOS/Windows batch
--type-add=batch:ext:bat,cmd

# ColdFusion
# https://en.wikipedia.org/wiki/ColdFusion
--type-add=cfmx:ext:cfc,cfm,cfml

# Clojure
# https://clojure.org/
--type-add=clojure:ext:clj,cljs,edn,cljc

# C
# .xs are Perl C files
--type-add=cc:ext:c,h,xs

# C header files
--type-add=hh:ext:h

# CoffeeScript
# https://coffeescript.org/
--type-add=coffeescript:ext:coffee

# C++
--type-add=cpp:ext:cpp,cc,cxx,m,hpp,hh,h,hxx

# C++ header files
--type-add=hpp:ext:hpp,hh,h,hxx

# C#
--type-add=csharp:ext:cs

# Crystal-lang
# https://crystal-lang.org/
--type-add=crystal:ext:cr,ecr

# CSS
# https://www.w3.org/Style/CSS/
--type-add=css:ext:css

# Dart
# https://dart.dev/
--type-add=dart:ext:dart

# Delphi
# https://en.wikipedia.org/wiki/Embarcadero_Delphi
--type-add=delphi:ext:pas,int,dfm,nfm,dof,dpk,dproj,groupproj,bdsgroup,bdsproj

# Elixir
# https://elixir-lang.org/
--type-add=elixir:ext:ex,exs

# Elm
# https://elm-lang.org
--type-add=elm:ext:elm

# Emacs Lisp
# https://www.gnu.org/software/emacs
--type-add=elisp:ext:el

# Erlang
# https://www.erlang.org/
--type-add=erlang:ext:erl,hrl

# Fortran
# https://en.wikipedia.org/wiki/Fortran
--type-add=fortran:ext:f,f77,f90,f95,f03,for,ftn,fpp

# Go
# https://golang.org/
--type-add=go:ext:go

# Groovy
# https://www.groovy-lang.org/
--type-add=groovy:ext:groovy,gtmpl,gpp,grunit,gradle

# GSP
# https://gsp.grails.org/
--type-add=gsp:ext:gsp

# Haskell
# https://www.haskell.org/
--type-add=haskell:ext:hs,lhs

# HTML
--type-add=html:ext:htm,html,xhtml

# Jade
# http://jade-lang.com/
--type-add=jade:ext:jade

# Java
# https://www.oracle.com/technetwork/java/index.html
--type-add=java:ext:java,properties

# JavaScript
--type-add=js:ext:js

# JSP
# https://www.oracle.com/technetwork/java/javaee/jsp/index.html
--type-add=jsp:ext:jsp,jspx,jspf,jhtm,jhtml

# JSON
# https://json.org/
--type-add=json:ext:json

# Kotlin
# https://kotlinlang.org/
--type-add=kotlin:ext:kt,kts

# Less
# http://www.lesscss.org/
--type-add=less:ext:less

# Common Lisp
# https://common-lisp.net/
--type-add=lisp:ext:lisp,lsp

# Lua
# https://www.lua.org/
--type-add=lua:ext:lua
--type-add=lua:firstlinematch:/^#!.*\blua(jit)?/

# Markdown
# https://en.wikipedia.org/wiki/Markdown
--type-add=markdown:ext:md,markdown
# We understand that there are many ad hoc extensions for markdown
# that people use.  .md and .markdown are the two that ack recognizes.
# You are free to add your own in your ackrc file.

# Matlab
# https://en.wikipedia.org/wiki/MATLAB
--type-add=matlab:ext:m

# Objective-C
--type-add=objc:ext:m,h

# Objective-C++
--type-add=objcpp:ext:mm,h

# OCaml
# https://ocaml.org/
--type-add=ocaml:ext:ml,mli,mll,mly

# Perl
# https://perl.org/
--type-add=perl:ext:pl,pm,pod,t,psgi
--type-add=perl:firstlinematch:/^#!.*\bperl/

# Perl tests
--type-add=perltest:ext:t

# Perl's Plain Old Documentation format, POD
--type-add=pod:ext:pod

# PHP
# https://www.php.net/
--type-add=php:ext:php,phpt,php3,php4,php5,phtml
--type-add=php:firstlinematch:/^#!.*\bphp/

# Plone
# https://plone.org/
--type-add=plone:ext:pt,cpt,metadata,cpy,py

# PureScript
# https://www.purescript.org
--type-add=purescript:ext:purs

# Python
# https://www.python.org/
--type-add=python:ext:py
--type-add=python:firstlinematch:/^#!.*\bpython/

# R
# https://www.r-project.org/
--type-add=rr:ext:R

# reStructured Text
# https://docutils.sourceforge.io/rst.html
--type-add=rst:ext:rst

# Ruby
# https://www.ruby-lang.org/
--type-add=ruby:ext:rb,rhtml,rjs,rxml,erb,rake,spec
--type-add=ruby:is:Rakefile
--type-add=ruby:firstlinematch:/^#!.*\bruby/

# Rust
# https://www.rust-lang.org/
--type-add=rust:ext:rs

# Sass
# https://sass-lang.com
--type-add=sass:ext:sass,scss

# Scala
# https://www.scala-lang.org/
--type-add=scala:ext:scala,sbt

# Scheme
# https://groups.csail.mit.edu/mac/projects/scheme/
--type-add=scheme:ext:scm,ss

# Shell
--type-add=shell:ext:sh,bash,csh,tcsh,ksh,zsh,fish
--type-add=shell:firstlinematch:/^#!.*\b(?:ba|t?c|k|z|fi)?sh\b/

# Smalltalk
# http://www.smalltalk.org/
--type-add=smalltalk:ext:st

# Smarty
# https://www.smarty.net/
--type-add=smarty:ext:tpl

# SQL
# https://www.iso.org/standard/45498.html
--type-add=sql:ext:sql,ctl

# Stylus
# http://stylus-lang.com/
--type-add=stylus:ext:styl

# SVG
# https://en.wikipedia.org/wiki/Scalable_Vector_Graphics
--type-add=svg:ext:svg

# Swift
# https://developer.apple.com/swift/
--type-add=swift:ext:swift
--type-add=swift:firstlinematch:/^#!.*\bswift/

# Tcl
# https://www.tcl.tk/
--type-add=tcl:ext:tcl,itcl,itk

# TeX & LaTeX
# https://www.latex-project.org/
--type-add=tex:ext:tex,cls,sty

# Template Toolkit (Perl)
# http//template-toolkit.org/
--type-add=ttml:ext:tt,tt2,ttml

# TOML
# https://toml.io/
--type-add=toml:ext:toml

# TypeScript
# https://www.typescriptlang.org/
--type-add=ts:ext:ts,tsx

# Visual Basic
--type-add=vb:ext:bas,cls,frm,ctl,vb,resx

# Verilog
--type-add=verilog:ext:v,vh,sv

# VHDL
# http://www.eda.org/twiki/bin/view.cgi/P1076/WebHome
--type-add=vhdl:ext:vhd,vhdl

# Vim
# https://www.vim.org/
--type-add=vim:ext:vim

# XML
# https://www.w3.org/TR/REC-xml/
--type-add=xml:ext:xml,dtd,xsd,xsl,xslt,ent,wsdl
--type-add=xml:firstlinematch:/<[?]xml/

# YAML
# https://yaml.org/
--type-add=yaml:ext:yaml,yml
HERE
    $lines =~ s/==VERSION==/$App::Ack::VERSION/sm;

    return $lines;
}

1;
