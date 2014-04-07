Changelog
=========

v0.2.0 (trunk)
--------------------

New Features:
 * Export of some advanced ctags annotations

Improvements:
 * New, more flexible database layout
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
