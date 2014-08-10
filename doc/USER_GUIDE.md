Starscope User Guide
====================

About
-----

Anyone who has done much programming in C (or C++) on a Unix-based OS has come
across the fantastic [Cscope](http://cscope.sourceforge.net/) tool. Sadly, it
only works for C (and sort of works for C++).

Starscope is a similar tool for [Ruby](https://www.ruby-lang.org/) and
[Golang](http://golang.org/), with a design intended to make it easy to add
[support for other languages](LANGUAGE_SUPPORT.md) within the same framework
(thus the name Starscope, i.e. \*scope).

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

Editor Integration
------------------

While there aren't any editors (that I know of) which interface natively with
Starscope, that isn't actually a problem. Almost all editors know how to
interface with Cscope and Ctags, and Starscope is able to export to both of
their file formats.

For Vim (which is what I use, so what I'm going to document) you can simply
tell Starscope to export to a cscope database (see the section on
[Exporting](#Exporting) below), then use Vim's [existing Cscope
integration](http://cscope.sourceforge.net/cscope_vim_tutorial.html) and
everything will Just Work :TM:.

Database Options
----------------

The default database is `.starscope.db` in the current directory. If you want
to use another file, specify one with `-f` or `--file`.

The default behaviour is always to read the database (if it exists), update it,
and write out the updated version. You can control this behaviour by passing any
of the `--no-read`, `--no-write` and `--no-update` flags.

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

Queries
-------

To query the starscope database, pass the `-q` or `--query` flag with an
argument in the following format: `TABLE,QUERY`. For example, `-q calls,new`
would list all callers of `new` and `-q defs,bar` would list places that define
a method or class named `bar`. See the [language support
documentation](LANGUAGE_SUPPORT.md) for a list of the most common tables, or use
the `--summary` flag to list all the tables in the current database.

You can also search for scoped names such as `MyClass.new`. To do this, you must
specify the scope with `::`, even if the language or instance you are searching
for uses another character like a dot. So, for example, `-q calls,MyClass::new`.

Queries using regular expressions are generally supported, and will be tried
against both the base name and the fully-qualified name (again using `::` as the
scope separator).

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
input is normally a query of the form `TABLE QUERY`, or a special command
starting with a `!`. Recognized special commands generally map to non-line-mode
options:
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
