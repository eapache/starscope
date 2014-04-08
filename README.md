StarScope
=========

[![Gem Version](https://badge.fury.io/rb/starscope.png)](http://badge.fury.io/rb/starscope)
[![Build Status](https://travis-ci.org/eapache/starscope.png?branch=master)](https://travis-ci.org/eapache/starscope)

Anyone who has done much programming in C (or C++) on a unix-based OS has come
across the fantastic [Cscope](http://cscope.sourceforge.net/) tool. Sadly, it
only works for C (and sort of works for C++).

StarScope is a similar tool for [Ruby](https://www.ruby-lang.org/) and
[Golang](http://golang.org/), with a design intended to make it easy to add
support for other languages at some point within the same framework (thus the
name StarScope, ie \*scope).

Install it as a gem:
```
$ gem install starscope
```

Build your database, by just running it in the project directory:
```
$ cd ~/my-project
$ starscope
```

Ask it things with the `-q` flag:
```
$ starscope -q calls,new # Lists all callers of new
```

Export it to various formats for use with your editor:
```
$ starscope -e ctags
$ starscope -e cscope
```

Other Uses
----------

StarScope is a supported backend for
[CodeQuery](https://github.com/ruben2020/codequery).
