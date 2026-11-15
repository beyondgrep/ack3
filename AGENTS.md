# AGENTS.md

Guidance for AI coding agents (and humans) working in the ack3 repository.

## What this project is

ack is a grep-like code-searching tool optimized for programmers searching
large source trees. It is written in Perl, distributed on CPAN as `ack`
(modules under `App::Ack::`), and also built as a single-file
"standalone" script. The author and maintainer is Andy Lester. Project
home: https://beyondgrep.com/. The license is the Artistic License 2.0.

The current version is in `lib/App/Ack.pm` (`$VERSION`) and in the `ack`
script itself. Current release line: v3.x.

## Repository layout

- `ack`: The main program (installed as the `ack` executable).
- `lib/App/Ack.pm`: Core logic and `$VERSION`.
- `lib/App/Ack/*.pm`: Supporting modules.
    - Config loading: `ConfigLoader`, `ConfigDefault`, `ConfigFinder`.
    - File walking: `Files`, `File`.
    - Filter system (`Filter/*.pm`): `Match`, `Extension`, `IsPath`, `FirstLineMatch`, `Collection`, `Inverse`, etc.
- `t/`: Test suite.
    - `*.t`: Perl tests.
    - `*.yaml`: data-driven CLI tests.
    - `Util.pm`: shared helpers.
    - `swamp/` and `text/`: fixture trees searched by the tests.
- `xt/`: Author/release tests: `coding-standards.t`, `pod.t`, `man.t`, `coresubs.t`.
- `dev/`: Developer tools and notes.
    - Scripts:
        - `timings.pl`: Times ack in common scenarios against a large checkout (Parrot is the usual one). Run `dev/timings.pl --help` for options. Used by `make timings`.
        - `display-option-coverage.pl`: Reads `opts.coverage` (written when `ACK_OPTION_COVERAGE` is set during `make test`) and prints the command-line options the test suite never uses.
        - `record-options`: Called by `t/Util.pm` for each ack command the test suite runs when `ACK_OPTION_COVERAGE` is set. It appends the options used to `opts.coverage`.
        - `generate-completion-scripts.pl`: Builds the bash and zsh completion scripts from the option list, with zsh descriptions. Used by `make completion.bash` and `make completion.zsh`.
        - `find-minimum-dep-versions.pl`: Searches for the oldest version of each dependency in `cpanfile` that ack still runs with. It checks each module alone, so it does not catch version combinations that fail together.
        - `crank-mutex`: Holds a table of mutually exclusive option combinations (`invalid_combinations`) for checking that ack rejects them.
        - `bench.pl`: Benchmarks four regex variants (plain, word-boundary, case-insensitive, and combinations) against one sample line with `Benchmark::timethese`.
        - `generate-rgb-codes.pl`: Prints the 216-color `Term::ANSIColor` cube as an HSL grid, for choosing highlight colors.
        - `issues-scrub.pl`: Maintainer tool. Lists open GitHub issues that lack a label or a milestone. Requires `Net::GitHub`.
        - `walk`: Lists every file under a directory with `File::Next`, unsorted, skipping `.svn` directories.
        - `linecount`: Counts lines in each `.txt` file under a directory.
        - `linecount-fork`: Same as `linecount`, but splits the work between a finder process and a counting process with a pipe.
    - Docker:
        - `docker/`: `Dockerfile`, `docker-compose.yml`, and `docker-entrypoint.sh` for a Perl 5.30 development environment with `File::Next` installed. Usage is in `DEVELOPERS.md`.
    - Release and reference documents:
        - `RELEASE-INSTRUCTIONS.md`: Step-by-step release process.
        - `Cookbook.pm`: Usage examples for ack, written as POD. Includes command pipelines and quoting notes for Windows.
        - `IGNORE.md`: Design notes on `--ignore-path` and the bugs reported against `--ignore-dir` and `--ignore-file`.
        - `multi-process.md`: Notes from Rob Hoelz on experiments with running ack across multiple worker processes.
        - `questions.md`: Q&A on filetype detection and shebang matching.
- `garage/`: Archived standalone builds of past releases (`ack-v3.x.y`). Do not modify.
- `squash`: Script that concatenates modules into `ack-standalone`.
- `tack`: Runs `blib/`-built ack from the repo root for quick manual testing.
- `Makefile.PL`, `cpanfile`, `MANIFEST`: Build and distribution metadata.
- `perlcriticrc`, `perltidyrc`: Lint and format configuration.
- `.github/workflows/testsuite.yml`: CI: tests on every supported Perl version since 5.10, plus Perl devel, on Linux and macOS.

Generated files (not committed; already in `.gitignore`): `Makefile`,
`MYMETA.*`, `blib/`, `ack-standalone`, `pm_to_blib`, `Build`, `*~`.

## Hard design constraints

These are settled design decisions (see `DESIGN.md`). Do not violate them
without an explicit decision from the maintainer.

- **Perl 5.10.1 or later, core modules plus `File::Next` only.** No Moose,
  Moo, or any other CPAN dependency. Do not use the smartmatch operator.
- **Must build as a single-file standalone script.** Its source must contain
  only characters in the range `[ -~]` (printable ASCII). `xt/coding-standards.t`
  enforces this, along with the module count below.
- **Must be distributable on CPAN** under the `App::Ack::` namespace.
- **Must run on Windows**, and under Perl taint mode.
- **No external tools.** ack never shells out to `file` or similar utilities.
- **Text detection uses Perl's `-T` operator.** Filetype detection is only by
  user-defined rules (the `--type` definitions).
- **Configuration is command-line only.** `.ackrc` files are just collections
  of command-line switches.
- **Not a sed.** ack does not replace text, edit files, or invoke editors.
- **No default sorting** of results. Sorting requires reading the whole
  directory first, which hurts performance on very large directories.
- **Be grep-compatible where possible** when deciding on behavior.

## Building and testing

Prerequisite check:

    perl -MFile::Next -E'say "ack is ready to build!"'

Build and test:

    perl Makefile.PL
    make
    make test            # runs test_classic and test_standalone

Individual targets:

    make test_classic     # tests against lib/ via blib/
    make test_standalone  # tests against the built ack-standalone
    make test_xt          # author tests in xt/
    make fulltest         # classic + standalone + xt
    make pytest           # runs the YAML-driven tests via t/run_yaml_test.py
    make ack-standalone   # build the single-file version
    make critic           # perlcritic with perlcriticrc

Running one test file (requires `make` first so `blib/` is current):

    prove -b t/context.t

Quick manual run of the built code from the repo root: `./tack <args>`
(again, run `make` first).

Test notes:

- `t/*.yaml` cases are run by `t/run_yaml_test.py` (pytest, requires PyYAML).
  Each case gives `args`, and optionally `stdout`, `stderr`, `exitcode`.
- `t/Util.pm` provides helpers (`prep_environment`, `create_globals`,
  `touch_ackrc`, `is_windows`, `has_io_pty`, and so on). Reuse them rather than
  reimplementing.
- Set `ACK_OPTION_COVERAGE=1` to record which options the suite exercises;
  `dev/display-option-coverage.pl` lists the ones it doesn't.
- Some tests are skipped on Windows and some need `IO::Pty`. Those skips are
  intentional, not failures.
- Setting `AUTHOR_TESTING`, `AUTOMATED_TESTING`, and `RELEASE_TESTING` to 1
  turns on extra checks. CI does this.

## Coding standards

- Keep `use strict; use warnings;` in every module and script.
- Format with `perltidy -pro=perltidyrc`; the config is in `perltidyrc`
  (120-column limit, 4-space indent, no tabs, preserved line endings).
- `make critic` must pass with `perlcriticrc`.
- Keep the code in the printable-ASCII range `[ -~]`. Use `\x{...}` escapes or
  similar if you need other characters in a test.
- Write new code that runs on Perl 5.10.1. Avoid newer syntax (signatures,
  postfix dereference, `//=` is fine since 5.10, but check each feature).
- `xt/coding-standards.t` asserts that there are exactly **20 `.pm` modules
  under `lib/` plus `ack`**. If you add or remove a module, update that count
  in the same change.
- New command-line options need tests. Look at existing `t/*.yaml` cases for
  the pattern.

## Changes, versioning, and releases

- Add user-visible changes to the `NEXT` section at the top of `Changes`,
  under a heading such as `[ENHANCEMENTS]`, `[FIXES]`, or `[SECURITY]`.
- Do not change the version number in ordinary development work. Version bumps
  and the release process are in `dev/RELEASE-INSTRUCTIONS.md`: update
  `$VERSION` in `lib/App/Ack.pm` and the `ack` script, update the `Changes`
  date and version heading, run `make disttest`, tag, and copy the standalone
  build into `garage/`.
- Keep `MANIFEST` in sync when you add or remove files that belong in the
  distribution (`make manifest` regenerates it).

## Git workflow

- The default and integration branch is `dev`. Create topic branches from
  `dev` and open pull requests against `dev`. (`DEVELOPERS.md` mentions
  `master`, but in this repository `dev` is the main branch.)
- Commits are cheap. Keep each commit focused, and write a message that says
  what changed and why.
- Do not commit or push unless asked.
- Do not edit `garage/` (archived releases), `tags`, or generated files.
- `Changes~` and editor swap files such as `.Changes.swp` are not project
  content. Do not commit them.

## Things to avoid

- Adding a CPAN dependency or a non-core Perl module.
- Adding non-ASCII characters to `ack` or any `lib/` module.
- Changing default output ordering, or adding text-editing behavior.
- Shelling out to external programs for detection or processing.
- Changing `garage/` contents or the `ack-v3.x.y` archives.
- Adding Perl features newer than 5.10.1 without checking the minimum version.

## Related projects

- **ripgrep** (`rg`) is a Rust code-search tool that was inspired by ack.
  It is a separate project with its own design. It respects `.gitignore` by
  default, where ack uses its own filetype rules and ignore settings. ack's
  constraints (Perl only, core modules plus `File::Next`, no external tools)
  are the reason ack does not follow ripgrep's implementation. Do not port
  ripgrep's design into ack without checking `DESIGN.md` first.

## Where to get more context

- `README.md`: user-facing overview and build instructions.
- `DEVELOPERS.md`: helper scripts, test rules, branching, and release notes.
- `DESIGN.md`: the inviolable design decisions and rejected features.
- `CONTRIBUTING.md`: how to request new filetypes (issue first, not a PR).
- `RELEASE-NOTES.md` and `Changes`: history.
