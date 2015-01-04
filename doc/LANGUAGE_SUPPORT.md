Language Support
================

Already Supported
-----------------

 * [Ruby](https://www.ruby-lang.org/)
 * [Golang](https://golang.org/)

How to Add Another Language
---------------------------

Adding support for a new language is really easy, and pretty generic - all of
the fancy features like cscope export should "just work" since they don't depend
on anything language-specific, they just read the internal database record
format.

For this doc, we're going to pretend to add support for a language called
"MyLanguage". Create a file called `mylanguage.rb` in `lib/starscope/langs/` and
drop the following template in:

```ruby
module Starscope::Lang
  module Mylanguage
    VERSION = 1

    def self.match_file(name)
      name.end_with?(".mylang")
    end

    def self.extract(file)
      # TODO
    end
  end
end
```

This code is pretty simple: we define a module called
`Starscope::Lang::Mylanguage` and give it one constant and two public module
methods:
 * `VERSION` is a constant integer defining the current version of the
   extractor. It should be incremented when the extractor has changed enough
   that any existing files should be re-parsed with the new version.
 * `match_file` takes the name of the file and returns a boolean if that file is
   written in MyLanguage or not. This can be as simple as checking the file
   extension (which the sample code does) or looking for a shell #! line, or
   anything you want.
 * `extract` takes a readable file handle pointing to the file, and must parse
   the file, `yield`ing records as it finds function definitions and the like.
   It may also return a final hash of file-wide metadata to store.

The record requirements are pretty straight-forward:
```ruby
yield table, name, extras={}
```
The first yielded argument must be the symbol of the table in which the record
belongs (basically its type). Current tables already include:
 * `calls` for function calls
 * `defs` for definitions of classes, functions, modules, etc.
 * `end` for the matching *end* of each definition
 * `assigns` for variable assignment
 * `requires` for required files in Ruby
 * `imports` for imported packages in Golang
 * `reads` for reading of variables, constants etc. (e.g. use in an expression)
 * `sym` for Ruby symbols

Try to use pre-existing tables where possible, but feel free to add more if the
language has some weird feature that doesn't map to any of the above. You don't
have to do anything special to create a new table, just yield the appropriate
symbol.

The second yielded argument is the name (string or symbol) of the token that
you want to add: the name of the function being called, or the name of the class
being defined, etc. If the name is scoped (such as "def MyModule::MyClass") pass
an array `["MyModule", "MyClass"]`.

Finally, the entirely-optional `extras` is a hash of whatever other extra values
you want. Some existing ones that you may want to use include:
 * `line_no` for the line (starting at 1) where the record occurs - this is
   necessary for cscope and ctags export
 * `col` for the column in the line where the name occurs
 * `type` for the type of definition (`:func`, `:class`, etc)

And that's it! Parse your files, yield your records, and the Starscope engine
takes care of everything else for you. If you've added support for a language
that you think others might find useful, please contribute it (with tests!) via
pull request.
