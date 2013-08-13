Changelog
=========

v0.1.2 (trunk)
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
