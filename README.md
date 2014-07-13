StarScope
=========

[![Gem Version](https://badge.fury.io/rb/starscope.png)](http://badge.fury.io/rb/starscope)
[![Build Status](https://travis-ci.org/eapache/starscope.png?branch=master)](https://travis-ci.org/eapache/starscope)

Anyone who has done much programming in C (or C++) on a unix-based OS has come
across the fantastic [Cscope](http://cscope.sourceforge.net/) tool. Sadly, it
only works for C (and sort of works for C++).

StarScope is a similar tool for [Ruby](https://www.ruby-lang.org/) and
[Golang](http://golang.org/), with a design intended to make it easy to add
support for other languages within the same framework (thus the name StarScope,
i.e. \*scope).

Install it as a gem:
```
$ gem install starscope
```

Build your database by just running it in the project directory:
```
$ cd ~/my-project
$ starscope
```

Ask it things directly:
```
$ starscope -q calls,new # Lists all callers of new
```

Export it to various formats for use with your editor:
```
$ starscope -e ctags
$ starscope -e cscope
```

More flags and options are available, run `starscope --help` for the complete list.

More Documentation
------------------

 * [User Guide](doc/USER_GUIDE.md)
 * [Database Format](doc/DB_FORMAT.md)
 * [Language Support](doc/LANGUAGE_SUPPORT.md)
 * [Version History](CHANGELOG.md)

Other Uses
----------

StarScope is a supported backend for
[CodeQuery](https://github.com/ruben2020/codequery).
