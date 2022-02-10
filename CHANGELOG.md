Changelog
=========

v1.6.0 (TODO)
-------------------

Improvements:
 * Support per-directory `.starscope.json` config (#181).
 * Support abbreviated special commands in line mode (e.g. `!u`, `!s`, `!q`).
 * Properly support non-ASCII identifiers in Golang.
 * Tiny performance improvements.

Bug Fixes:
 * Strip non-ASCII characters from cscope export to avoid cscope crashes (#182).

Misc:
 * Drop support for ancient Marshall-format databases.
 * Drop support for several old Ruby versions. 2.6 is now the oldest supported.
 * Dependency upgrades.
 * Documentation improvements.

v1.5.7 (2019-04-04)
--------------------

 * Use binary mode for file writes to fix compatibility on MS Windows (#171).
 * Make sure the database is still valid when a parse exception happens (#173).
 * Fix handling of `__ENCODING__` literals in ruby parser (#174).
 * Update some dependencies.

v1.5.6 (2018-01-16)
--------------------

 * Be more lenient parsing ERB files: accept some of Erubi's expanded syntax.
 * Drop support for ruby 1.9.3.
 * Update some dependencies.

v1.5.5 (2017-01-02)
--------------------

Bug Fixes:
 * Hotfix for missing `require` preventing export in v1.5.4.

v1.5.4 (2017-01-01)
--------------------

Improvements:
 * When dumping file metadata, don't include the file contents.

Bug Fixes:
 * Fix parsing ruby files with invalidly-encoded literals (#160).
 * Fix exporting ctags files to different output directories (#163).

v1.5.3 (2016-03-02)
--------------------

Improvements:
 * Skip minified javascript files.

Bug Fixes:
 * Fix javascript parsing of `require` calls that are actually methods and not
   CommonJS-style imports (#158).

v1.5.2 (2016-01-12)
--------------------

Misc:
 * Relax some dependencies to handle e.g. the upcoming parser release for Ruby
   2.3 (#149).
 * Rename the `Go` extractor to `Golang` so that it is named consistently
   everywhere (#143).

v1.5.1 (2015-10-14)
--------------------

Improvements:
 * Support CommonJS require syntax and ES6 import syntax in JavaScript (#146).

Bug Fixes:
 * Fix handling of Ctrl-C in line-mode to exit cleanly instead of crashing.
 * Fix handling of braceless fat-arrow methods in JavaScript (#147).

v1.5.0 (2015-09-24)
--------------------

New Features:
 * Javascript support, including basic ES6/ES7 and JSX (via Babel).
 * Implemented `--force-update` flag to rescan all files even if they apparently
   haven't changed (#139).
 * Added support for a shared configuration file in `~/starscope.json` (#140).
   This is primarily useful for commonly excluded files (e.g. `cscope.out`).

Bug Fixes:
 * Fixed a really weird corruption in certain rare cscope export cases (#129).

Misc:
 * Drop support for ruby 1.8.7, it was getting annoying and is long unsupported.

v1.4.1 (2015-09-12)
--------------------

Misc:
 * Minor code style cleanups and documentation improvements.
 * Bumped a few dependencies.
 * Official support for ruby 2.2 although it already worked.

v1.4.0 (2015-06-19)
--------------------

New Features:
 * Implement support for files with multiple nested languages (#61).
 * Implement support for extracting ruby inside ERB files (#120).

Bug Fixes:
 * Correctly handle the removal of language extractors (#122).

Misc:
 * Preliminary use of Rubocop for more consistent code style.
 * Document the fact that `!` can't be used at the beginning of table names.

v1.3.3 (2015-03-07)
--------------------

Bug Fixes:
 * Escape '/' characters in the line 'pattern' component of ctags records, since
   otherwise they terminate that component when it is read as a vim search
   command.

Improvements:
 * Recognize rake tasks as ruby files.

v1.3.2 (2015-02-13)
--------------------

Bug Fixes:
 * Forcefully require latest ruby parser gem to pull in the fix for
   https://github.com/whitequark/parser/issues/186
 * Wrap reported exceptions in quotes for clarity.

v1.3.1 (2015-01-22)
--------------------

Bug Fixes:
 * Fix parsing of certain queries containing `:`.
 * Fix alignment of summaries on large DBs.

v1.3.0 (2015-01-04)
--------------------

New Features:
 * Give `*` as the table name in order to query all tables at once (#58).
 * Specify filters for your queries for example `lang:ruby,calls,new` (#24).
 * Ruby: Recognize variables and symbols outside of assignments, available in
   the new `reads` and `sym` tables (#102).
 * Cscope: export 'unmarked' or generic cscope tokens, providing a much richer
   integration with cscope's "find this C symbol" (#60).

Bug Fixes:
 * Simplify query logic to match user expectations (#91).
 * Cscope: fix export of inline function definitions.
 * DB: fix saving of upconverted databases in rare circumstances.

v1.2.0 (2014-09-02)
--------------------

Improvements:
 * You can now specify `--export` multiple times with different formats in a
   single run.
 * Language extractors are now individually versioned. When an extractor is
   upgraded, files it owns will be automatically re-parsed.
 * Deduplicated some metadata, shrinking database size. This comes with a
   related reduction in read/write time and memory usage.

Bug Fixes:
 * Proper handling of golang string literal escapes.

Misc:
 * Lots of internal refactoring and test suite improvements for better
   maintainability going forward.

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
 * Import new ruby parser version and make necessary changes so that Starscope
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
