Starscope
=========

[![Gem Version](https://badge.fury.io/rb/starscope.svg)](https://badge.fury.io/rb/starscope)
[![Build Status](https://travis-ci.org/eapache/starscope.svg?branch=master)](https://travis-ci.org/eapache/starscope)
[![Code of Conduct](https://img.shields.io/badge/code%20of%20conduct-active-blue.svg)](https://eapache.github.io/conduct.html)

Anyone who has done much programming in C (or C++) on a Unix-based OS has come
across the fantastic [Cscope](http://cscope.sourceforge.net/) tool. Sadly, it
only works for C (and sort of works for C++).

Starscope is a similar tool for [Ruby](https://www.ruby-lang.org/) and
[Golang](https://golang.org/), with a design intended to make it easy to add
[support for other languages](doc/LANGUAGE_SUPPORT.md) within the same framework
(thus the name Starscope, i.e. \*scope).

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
 * [Database Format](doc/DB_FORMAT.md)
 * [Language Support](doc/LANGUAGE_SUPPORT.md)
 * [Version History](CHANGELOG.md)

Other Uses
----------

- Starscope is a supported backend for
[CodeQuery](https://github.com/ruben2020/codequery).
- Starscope has been [packaged for Arch
  Linux](https://aur.archlinux.org/packages/ruby-starscope/).
