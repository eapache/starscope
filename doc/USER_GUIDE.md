Starscope User Guide
====================

* [About](#about)
* [Installation](#installation)
* [Quick Start](#quick-start)
* [Editor and Workflow Integration](#editor-and-workflow-integration)
* [Database Options](#database-options)
* [Paths](#paths)
* [Queries](#queries)
* [Exporting](#exporting)
* [Line-Mode](#line-mode)
* [Miscellaneous](#miscellaneous)

About
-----

Anyone who has done much programming in C (or C++) on a Unix-based OS has come
across the fantastic [Cscope](http://cscope.sourceforge.net/) tool. Sadly, it
only works for C (and sort of works for C++).

Starscope is a similar tool for [Ruby](https://www.ruby-lang.org/),
[Golang](https://golang.org/), and
[JavaScript](https://en.wikipedia.org/wiki/JavaScript), with a design intended
to make it easy to add [support for other languages](LANGUAGE_SUPPORT.md)
within the same framework (thus the name Starscope, i.e. \*scope).

Installation
------------

Starscope is a ruby gem available at https://rubygems.org/gems/starscope.
Install it with:
```
$ gem install starscope
```

This should place a program called `starscope` in your path.

Quick Start
-----------

Build your database by just running it in the project directory:
```
$ cd ~/my-project
$ starscope
```

Ask it things directly:
```
$ starscope -q calls,new # Lists all callers of new
```

Export it to various existing formats for automatic integration with your editor:
```
$ starscope -e ctags
$ starscope -e cscope
```

Editor and Workflow Integration
-------------------------------

While I don't know of any editors that interface natively with Starscope
(if you find one, let me know!) there is a much simpler solution. Almost
all modern editors know how to read Cscope and Ctags files, and Starscope
can export to both of those file formats. Simply export to the appropriate
file (see the section on [Exporting](#exporting) below), then use your
editor's existing integration and it should just work.

Many people also like to have this kind of tool automatically run when
certain events happen, such as a `git commit`. Tim Pope has an excellent
article on [how to do this with Ctags](http://tbaggery.com/2011/08/08/effortless-ctags-with-git.html)
and with Starscope it is even simpler. Just place the line
`starscope --quiet -e cscope &` into the hooks documented by Tim.

Database Options
----------------

The default database is `.starscope.db` in the current directory. If you want
to use another file, specify one with `-f` or `--file`.

The default behaviour is always to read the database (if it exists), update it,
and write out the updated version. You can control this behaviour by passing any
of the `--no-read`, `--no-write` and `--no-update` flags. If you pass the
`--force-update` flag then all files and directories will be re-scanned, not
just the ones that have changed.

To get a summary of the current database contents, pass the `-s` or `--summary`
flag.

Paths
-----

Starscope has powerful options with sane defaults for managing which paths get
scanned for files and which do not. By default when creating a new database,
Starscope will scan all files recursively in the current directory. To scan
specific paths or files instead, pass them as arguments (so `starscope myfolder`
would only scan files in `myfolder/`).

Paths are saved in the database metadata - once you have created a database with
custom paths, all subsequent operations will remember and use those paths even
when they are not explicitly specified. At any time, specifying *more* paths
will add them (and the files they contain) to the database without removing any
existing paths.

You can also exclude certain paths from processing by passing the `-x` or
`--exclude` flag with the desired pattern. In a new project, `starscope
--exclude test/` will scan all files *except* the ones in the `test/` directory.
Excluded patterns are also remembered, and can be added at any time. If an
existing file in the database matches a newly added exclusion rule, it will be
removed.

You can exclude files on a per-directory basis by creating a `.starscope.json`
file in a given directory with contents like:
```json
{
  "excludes": ["foo", "bar/", "**/*.ext"]
}
```

For commonly excluded files you can create a home directory config file at 
`~/.starscope.json`. Patterns listed there will be excluded from all starscope 
databases by default.

Queries
-------

To query the starscope database, pass the `-q` or `--query` flag with an
argument in the following format: `[FILTERS,]TABLE,QUERY`. For example,
`-q calls,new` would list all callers of `new` and `-q defs,bar` would list
places that define a method or class named `bar`. See the [language support
documentation](LANGUAGE_SUPPORT.md) for a list of the most common tables, or use
the `--summary` flag to list all the tables in the current database. Pass `*` as
the table name to query all tables.

You can also search for scoped names such as `MyClass.new`. To do this, you must
specify the scope with `::`, even if the language or instance you are searching
for uses another character like a dot. So, for example, `-q calls,MyClass::new`.

Queries using regular expressions are generally supported, and will be tried
against both the base name and the fully-qualified name (again using `::` as the
scope separator).

You can optionally filter records based on their metadata prior to the actual
query, by prefixing comma-separated `KEY:VALUE` pairs to the query string. A
common use of this is to restrict a query to files of a given language, for
example with `-q lang:ruby,calls,new`.

Exporting
---------

Starscope can export its database into two other formats for use with
third-party tools:
 * cscope format (default path: `cscope.out`)
 * ctags format (default path: `tags`)

To export, pass the `-e` or `--export` flag with one of the above formats. Each
format has its own default path which is where the exported file will go. If you
want to specify a custom location, append it after the format with a comma (so
`--export cscope,myfile` would export to `myfile` in the cscope format).

You can also dump entire tables (or the entire database) to raw text output for
manual inspection. This is mostly useful for debugging, but means you can pipe
it to sed (for example) if you wanted to do something fancy. This can be done
with the `-d` or `--dump` flag, which takes an optional argument of which table
to dump (if no table is specified, it dumps all tables).

Line-Mode
---------

Specifying `-l` or `--line-mode` places you into line-oriented mode, letting you
run multiple queries without reloading the database each time. In line mode,
input is normally a query of the form `[FILTERS ]TABLE QUERY`, or a special
command starting with a `!`. Recognized special commands generally map to
non-line-mode options:
 * `!dump [TABLE]` - same as the `--dump` flag
 * `!export FORMAT[,PATH]` - same as the `--export` flag
 * `!summary` - same as the `--summary` flag
 * `!update` - updates the database without exiting line-mode
 * `!help` - prints basic line-mode help
 * `!version` - same as the `--version` flag
 * `!quit` - exit line-mode


Miscellaneous
-------------

Pass `-h` or `--help` to get a brief summary of the availble options.

Pass `-v` or `--version` to get the current version number.

Pass `--verbose` to get a great deal more output about what it is doing.

Pass `--quiet` to remove all non-critical output (you will still get error
messages, query results, etc).
