Changelog
=========

v1.2.0 (trunk)
--------------------

Improvements:
 * You can now specify `--export` multiple times with different formats in a
   single run.

Bug Fixes:
 * Proper handling of golang string literal escapes.

v1.1.2 (2014-07-29)
--------------------

Bug Fixes:
 * Don't crash exporting to cscope if tokens overlap.
 * In golang, don't parse inside string literals.

v1.1.1 (2014-07-21)
--------------------

New Features:
 * Export of ctags `language` tag (needed for `YouCompleteMe` support).

Bug Fixes:
 * In ruby, correctly report calls to functions such as `foo=` as assignments to
   `foo`.

v1.1.0 (2014-07-16)
--------------------

Bug Fixes:
 * Fixed cscope export when the string for a token appeared multiple times on
   the same line, for example the function call `go("go")`.
 * Fixed cscope export of function calls made from the global scope.
 * Fixed cscope export of functions that end in punctuation (e.g. `include?`)
 * Fixed golang parsing of global function calls.
 * Fixed crash in line-mode when pressing `<return>` with no input.

Improvements:
 * Optimized and refactored database update path. Now much simpler and about 8%
   faster.
 * Documented the database format and language API. Added a user guide which is
   much more complete than the simpler output of the `--help` flag.

Misc:
 * Rename --no-progress to --quiet, and make sure all operations provide some
   indication of success/failure except when quieted.
 * Dynamically load language extractors, so new ones can be dropped in with no
   other code changes.

v1.0.4 (2014-06-10)
--------------------

Improvements:
 * Optimized deleting stale records.

v1.0.3 (2014-06-10)
--------------------

Improvements:
 * Optimized extracting lines from parsed files.

Misc:
 * Code cleanup.

v1.0.2 (2014-04-19)
--------------------

Bug Fixes:
 * Fix an exception when updating the db from line mode.
 * Make sure to mark the db as changed when a source file has been deleted

Misc:
 * A few trivial tweaks and optimizations.
 * Store the application version in the db metadata for more fine-grained
   forwards-compatibility.
 * Permit exporting from line mode.

v1.0.1 (2014-04-16)
--------------------

Bug Fixes:
 * Stupid forgot-to-change-the-gemspec to actually permit installing on Ruby
   1.8.7!

v1.0.0 (2014-04-16)
--------------------

New Features:
 * Preliminary export of a few advanced ctags annotations
 * New -x flag to exclude files from scan (such as compiled .o files)
 * New --verbose flag for additional output

Bug Fixes:
 * Correctly write out migrated databases
 * Be compatible with ruby 1.8 everywhere
 * Fix golang parsing untyped "var" declarations
 * Fix golang parsing multi-line literals
 * Record assignments to ruby constants as definitions
 * Fix exporting to cscope when scanned files contain invalid unicode

Improvements:
 * Faster file-type matching
 * Reworked option flags:
   * Merged -r and -w into -f
   * Split -n into --no-read, --no-write, --no-update
 * New, more flexible database format
 * Substantially improved searching/matching logic
 * Miscellanious others via updated dependencies

v0.1.10 (2014-02-24)
--------------------

Improvements:
 * Import new ruby parser version and make necessary changes so that StarScope
   now runs on older Ruby versions (1.9.2 and 1.8.7)

v0.1.9 (2014-02-22)
-------------------

Bug Fixes:
 * Work around what appears to be a bug in time comparison in certain Ruby
   version by casting times to ints before comparing them. Fixes cases where
   files were being rescanned even when they hadn't changed.

v0.1.8 (2014-02-22)
-------------------

Bug Fixes:
 * Correctly handle empty files in ruby parser (#12)

v0.1.7 (2014-01-14)
-------------------

Improvements:
 * Much better recognition and parsing of definitions and assignments to
   variables and constants in golang code (fixes #11 among others).

Infrastructure:
 * Test suite and continuous integration (via Minitest and Travis-CI).
 * Use github's tickets instead of a TODO file.

v0.1.6 (2014-01-10)
-------------------

Improvements:
 * Better recognition of golang function calls.

v0.1.5 (2014-01-06)
-------------------

New Features:
 * Add --no-progress option to hide progress-bar.

Misc:
 * Explicitly print "No results found" to avoid mysterious empty output.
 * Recognize ruby files with a #!ruby line but no .rb suffix.
 * Help output now fits in 80-column terminal.

v0.1.4 (2014-01-05)
-------------------

New Features:
 * Export to cscope databases.
 * Regexes are now accepted in the last ('key') term of a query

Bug Fixes:
 * Don't match Golang function names ending with a dot.

Misc:
 * Dumping tables now sorts by key.
 * Various bugfixes and improvements via updated dependencies.

v0.1.3 (2013-10-15)
-------------------

Misc:
 * New upstream ruby parser release.

v0.1.2 (2013-08-14)
-------------------

Bug Fixes:
 * Ensure key is always a symbol (fixes database updates for Go files).

v0.1.1 (2013-08-12)
-------------------

New Features:
 * Support for Google's go (AKA golang).

v0.1.0 (2013-08-08)
-------------------

New Features:
 * Progress bar when building or updating database.

Bug Fixes:
 * Handle the case when a ruby file produces a nil parse tree.
 * Many misc fixes.

Internals:
 * Another new version of the ruby parser.
 * Replace the default JSON module with Oj, which is more than twice as fast for
   large databases.
 * Misc optimizations.

v0.0.8 (2013-07-20)
-------------------

Bug Fixes:
 * Correctly format table dumps.
 * Correctly generate `defs` table entries for static methods (Bug #1)

v0.0.7 (2013-07-19)
-------------------

Misc:
 * Specify license in gemspec.

v0.0.6 (2013-07-19)
-------------------

Interface:
 * Table names are now consistently conjugated (def -> defs, assign -> assigns)
 * The `starscope` binary no longer has an unnecessary .rb suffix.

Internals:
 * Update to a new version of the ruby parser that is significantly faster.
 * Database is now stored as gzipped JSON for better portability

v0.0.5 (2013-06-22)
-------------------

New Features:
 * Export to ctags files

Improvements:
 * GNU Readline behaviour in line-mode
 * Additional commands available in line-mode: !dump, !help, !version
 * Prints the relevant line in query mode

v0.0.4 (2013-06-08)
-------------------

New Features:
 * Line-mode (use the `-l` flag)

Other Improvements:
 * Better error handling
 * General polish
