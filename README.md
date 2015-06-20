Starscope
=========

[![Gem Version](https://img.shields.io/gem/v/starscope.svg)](https://rubygems.org/gems/starscope)
[![Build Status](https://travis-ci.org/eapache/starscope.svg?branch=master)](https://travis-ci.org/eapache/starscope)
[![Code of Conduct](https://img.shields.io/badge/code%20of%20conduct-active-blue.svg)](https://eapache.github.io/conduct.html)

Starscope is a code indexer, search and navigation tool for
[Ruby](https://www.ruby-lang.org/) and [Golang](https://golang.org/), with a
design intended to make it easy to add
[support for other languages](doc/LANGUAGE_SUPPORT.md).

Inspired by the extremely popular [Ctags](https://en.wikipedia.org/wiki/Ctags)
and [Cscope](http://cscope.sourceforge.net/) utilities, Starscope can answer a
lot of questions about your code. It can tell you:
 - where methods are defined
 - where methods are called
 - where variables are assigned
 - where symbols are used
 - where files and libraries are imported or required

While Ctags already supports Ruby and Go, it can only tell you where things are
defined. Cscope can answer a lot more of your questions, but it is limited to
just the C language family. Starscope was written to combine the power of
Cscope with the flexibility of Ctags, bringing full code indexing to as many
developers as possible.

Quick Start
-----------

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

Export it to various existing formats for automatic integration with your editor:
```
$ starscope -e ctags
$ starscope -e cscope
```

More Documentation
------------------

 * [User Guide](doc/USER_GUIDE.md)
 * [Version History](CHANGELOG.md)
 * [Language Support](doc/LANGUAGE_SUPPORT.md)
 * [Database Format](doc/DB_FORMAT.md)

Other Uses
----------

- Starscope is a supported backend for
[CodeQuery](https://github.com/ruben2020/codequery).
- Starscope has been [packaged for Arch
  Linux](https://aur.archlinux.org/packages/ruby-starscope/).
