StarScope
=========

https://rubygems.org/gems/starscope

*Note to those users looking at the GitHub language statistics: there is no perl
here, that is their bug to fix.*

Anyone who has done much programming in C (or C++) on a unix-based OS has come
across the fantastic Cscope tool [1]. Sadly, it only works for C (and sort of
works for C++).

StarScope is a similar tool for Ruby and Go, with a design intended to make it
easy to add support for other languages at some point within the same framework
(thus the name StarScope, ie \*scope).

Install it as a gem:
```
$ gem install starscope
```

Build your database, by just running it in the project directory:
```
$ cd ~/my-project
$ starscope
```

Ask it things with `-q`
```
$ starscope -q calls,new # Lists all callers of new
```

Export it for use with your editor
```
$ starscope -e ctags
```

[1] http://cscope.sourceforge.net/
