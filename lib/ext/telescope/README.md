# Telescope

Telescope is a highly customizable test library for Lua that allows for
declarative tests with nested contexts.

## Features

* Compatible with Lua 5.1 and 5.2.
* Nestable test contexts/descriptions.
* [BDD](http://en.wikipedia.org/wiki/Behavior_Driven_Development)-style spec names.
* Before/after functions per context.
* Integrated code coverage reports using [Luacov](http://luacov.luaforge.net/).
* You can easily add your own assertions.
* Many different formatting options for tests and reports.
* Simple, well documented API makes it easy to extend/hack.
* Command line runner allows you to input Lua snippet callbacks, so you can, for example,
  drop to a debugger on failed tests, or wrap test calls around a profiler, etc.

## An Example

    context("A context", function()
      before(function() end)
      after(function() end)
      context("A nested context", function()
        test("A test", function()
          assert_not_equal("ham", "cheese")
        end)
        context("Another nested context", function()
          test("Another test", function()
            assert_greater_than(2, 1)
          end)
        end)
      end)
      test("A test in the top-level context", function()
        assert_equal(3, 1)
      end)
    end)

## Getting it

You can install Telescope using Luarocks:

    sudo luarocks install telescope

You can also check out the source code from Git, and  install via "make" if you
prefer:

    git clone git://github.com/norman/telescope.git
    cd telescope
    make install

Note that compatibility with Lua 5.2 has recently been added, but is not yet in
Luarocks. If you want support for 5.2, for now please install via make.

The source code can be found at:

    https://github.com/norman/telescope


## Running your tests

Telescope comes with a command-line test runner named `tsc`. Simply run:

    tsc my_test_file.lua

Or perhaps

    tsc -f test/*.lua

The full test output (what you get using "-f") from the examples given would be:

    ------------------------------------------------------------------------
    A context:
    A nested context:
      A test                                                             [P]
      Another nested context:
        Another test                                                     [P]
    A test in the top-level context                                      [F]
    ------------------------------------------------------------------------
    A test with no context                                               [U]
    Another test with no context                                         [U]
    ------------------------------------------------------------------------
    This is a context:
    This is another context:
      this is a test                                                     [U]
      this is another test                                               [U]
      this is another test                                               [U]
    ------------------------------------------------------------------------
    8 tests 2 passed 3 assertions 1 failed 0 errors 5 unassertive 0 pending

    A test in the top-level context:
    Assert failed: expected '3' to be equal to '1'
    stack traceback:
      ...ib/luarocks/rocks//telescope/scm-1/lua/telescope.lua:139: in function 'assert_equal'
      example.lua:18: in function <example.lua:17>
      [C]: in function 'pcall'
      ...ib/luarocks/rocks//telescope/scm-1/lua/telescope.lua:330: in function 'invoke_test'
      ...ib/luarocks/rocks//telescope/scm-1/lua/telescope.lua:362: in function 'run'
      ...usr/local/lib/luarocks/rocks//telescope/scm-1/bin/ts:147: in main chunk
      [C]: ?

Telescope tells you which tests were run, how many assertions they called,
how many passed, how many failed, how many produced errors, how many provided
a name but no implementation, and how many didn't assert anything. In the event
of any failures or errors, it shows you stack traces.

You can customize the test output to be as verbose or silent as you want, and
easily write your own test reporters - the source is well documented.

You can pass in snippets of Lua code on the command line to run as callbacks
for various test success/failure scenarios, and easily customize the output or
  use Telescope with other applications.

You can see all the available command-line options, and some examples by running:

    tsc -h

### More Examples

    -- Tests can be outside of contexts, if you want
    test("A test with no context", function()
    end)

    test("Another test with no context", function()
    end)

    -- Contexts and tests with various aliases
    spec("This is a context", function()
      describe("This is another context", function()
        it("this is a test", function()
        end)
        expect("this is another test", function()
        end)
        should("this is another test", function()
        end)
      end)
    end)

### Even More Examples

    -- change the name of your test or context blocks if you want something
    -- different
    telescope.context_aliases = {"specify"}
    telescope.test_aliases = {"verify"}

    -- create your own assertions
    telescope.make_assertion("longer_than", "%s to be longer than %s chars",
      function(a, b) return string.len(a) > b end)
    -- creates two assertions: assert_longer_than and assert_not_longer_than,
    -- which give error messages such as:
    -- Assertion error: expected "hello world" to be longer than 25 chars
    -- Assertion error: expected "hello world" not to be longer than 2 chars

    -- create a test runner with callbacks to show progress and
    -- drop to a debugger on errors
    local contexts = telescope.load_contexts(file)
    local results = telescope.run(contexts, {
     after = function(t) io.stdout:write(t.status_label) end,
     error = function(t) debug.debug() end
    })

    -- call "tsc" on the command line with a callback to generate a custom report
    tsc --after="function(t) print(t.status_label, t.name, t.context) end" example.lua

## Author

[Norman Clarke](mailto:norman@njclarke.com)

Please feel free to email me bug reports or feature requests.

## Acknowledgements

Telescope's initial beta release was made on Aug 25, 2009 - the 400th
anniversary of the invention of the telescope.

Thanks to [ScrewUnit](http://github.com/nathansobo/screw-unit/tree/master),
[Contest](http://github.com/citrusbyte/contest) and
[Luaspec](http://github.com/mirven/luaspec/) for inspiration.

Thanks to [Eric Knudtson](http://twitter.com/vikingux) for helping me come up
with the name "Telescope."

## License ##

The MIT License

Copyright (c) 2009-2012 [Norman Clarke](mailto:norman@njclarke.com)

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
