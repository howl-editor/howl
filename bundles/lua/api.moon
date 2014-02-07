-- Lua API documentation, automatically compiled for Howl from
-- http://www.lua.org/manual/5.2/manual.html
--
-- by Roberto Ierusalimschy, Luiz Henrique de Figueiredo, Waldemar Celes
-- Copyright © 2011–2013 Lua.org, PUC-Rio. Freely available under the terms of the Lua license.
--
-- Copyright © 1994–2014 Lua.org, PUC-Rio.
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy of
-- this software and associated documentation files (the "Software"), to deal in
-- the Software without restriction, including without limitation the rights to
-- use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
-- the Software, and to permit persons to whom the Software is furnished to do so,
-- subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING -- BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND -- NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.
{
  "and": {
    "description": "Lua keyword",
    "signature": "and"
  },
  "break": {
    "description": "Lua keyword",
    "signature": "break"
  },
  "do": {
    "description": "Lua keyword",
    "signature": "do"
  },
  "elseif": {
    "description": "Lua keyword",
    "signature": "elseif"
  },
  "else": {
    "description": "Lua keyword",
    "signature": "else"
  },
  "end": {
    "description": "Lua keyword",
    "signature": "end"
  },
  "false": {
    "description": "Lua keyword",
    "signature": "false"
  },
  "for": {
    "description": "Lua keyword",
    "signature": "for"
  },
  "function": {
    "description": "Lua keyword",
    "signature": "function"
  },
  "goto": {
    "description": "Lua keyword",
    "signature": "goto"
  },
  "if": {
    "description": "Lua keyword",
    "signature": "if"
  },
  "in": {
    "description": "Lua keyword",
    "signature": "in"
  },
  "local": {
    "description": "Lua keyword",
    "signature": "local"
  },
  "nil": {
    "description": "Lua keyword",
    "signature": "nil"
  },
  "not": {
    "description": "Lua keyword",
    "signature": "not"
  },
  "or": {
    "description": "Lua keyword",
    "signature": "or"
  },
  "repeat": {
    "description": "Lua keyword",
    "signature": "repeat"
  },
  "return": {
    "description": "Lua keyword",
    "signature": "return"
  },
  "then": {
    "description": "Lua keyword",
    "signature": "then"
  },
  "true": {
    "description": "Lua keyword",
    "signature": "true"
  },
  "until": {
    "description": "Lua keyword",
    "signature": "until"
  },
  "while": {
    "description": "Lua keyword",
    "signature": "while"
  },
  "assert": {
    "description": "# assert (v {, message})\nIssues an error when the value of its argument `v` is false (i.e.,\n**nil** or **false**); otherwise, returns all its arguments. `message`\nis an error message; when absent, it defaults to \"assertion failed!\"",
    "signature": "assert (v {, message})"
  },
  "collectgarbage": {
    "description": "# collectgarbage ({opt {, arg}})\nThis function is a generic interface to the garbage collector. It\nperforms different functions according to its first argument, `opt`:\n\n-   **\"`collect`\":** performs a full garbage-collection cycle. This is\n    the default option.\n-   **\"`stop`\":** stops automatic execution of the garbage collector.\n    The collector will run only when explicitly invoked, until a call to\n    restart it.\n-   **\"`restart`\":** restarts automatic execution of the garbage\n    collector.\n-   **\"`count`\":** returns the total memory in use by Lua (in Kbytes)\n    and a second value with the total memory in bytes modulo 1024. The\n    first value has a fractional part, so the following equality is\n    always true:\n\n             k, b = collectgarbage(\"count\")\n             assert(k*1024 == math.floor(k)*1024 + b)\n\n    (The second result is useful when Lua is compiled with a non\n    floating-point type for numbers.)\n\n-   **\"`step`\":** performs a garbage-collection step. The step \"size\" is\n    controlled by `arg` (larger values mean more steps) in a\n    non-specified way. If you want to control the step size you must\n    experimentally tune the value of `arg`. Returns **true** if the step\n    finished a collection cycle.\n-   **\"`setpause`\":** sets `arg` as the new value for the *pause* of the\n    collector (see {§2.5}(#2.5)). Returns the previous value for\n    *pause*.\n-   **\"`setstepmul`\":** sets `arg` as the new value for the *step\n    multiplier* of the collector (see {§2.5}(#2.5)). Returns the\n    previous value for *step*.\n-   **\"`isrunning`\":** returns a boolean that tells whether the\n    collector is running (i.e., not stopped).\n-   **\"`generational`\":** changes the collector to generational mode.\n    This is an experimental feature (see {§2.5}(#2.5)).\n-   **\"`incremental`\":** changes the collector to incremental mode. This\n    is the default mode.",
    "signature": "collectgarbage ({opt {, arg}})"
  },
  "dofile": {
    "description": "# dofile ({filename})\nOpens the named file and executes its contents as a Lua chunk. When\ncalled without arguments, `dofile` executes the contents of the standard\ninput (`stdin`). Returns all values returned by the chunk. In case of\nerrors, `dofile` propagates the error to its caller (that is, `dofile`\ndoes not run in protected mode).",
    "signature": "dofile ({filename})"
  },
  "error": {
    "description": "# error (message {, level})\nTerminates the last protected function called and returns `message` as\nthe error message. Function `error` never returns.\n\nUsually, `error` adds some information about the error position at the\nbeginning of the message, if the message is a string. The `level`\nargument specifies how to get the error position. With level 1 (the\ndefault), the error position is where the `error` function was called.\nLevel 2 points the error to where the function that called `error` was\ncalled; and so on. Passing a level 0 avoids the addition of error\nposition information to the message.",
    "signature": "error (message {, level})"
  },
  "_G": {
    "description": "# _G\nA global variable (not a function) that holds the global environment\n(see {§2.2}(#2.2)). Lua itself does not use this variable; changing its\nvalue does not affect any environment, nor vice-versa.",
    "signature": "_G"
  },
  "getmetatable": {
    "description": "# getmetatable (object)\nIf `object` does not have a metatable, returns **nil**. Otherwise, if\nthe object's metatable has a `\"__metatable\"` field, returns the\nassociated value. Otherwise, returns the metatable of the given object.",
    "signature": "getmetatable (object)"
  },
  "ipairs": {
    "description": "# ipairs (t)\nIf `t` has a metamethod `__ipairs`, calls it with `t` as argument and\nreturns the first three results from the call.\n\nOtherwise, returns three values: an iterator function, the table `t`,\nand 0, so that the construction\n\n         for i,v in ipairs(t) do body end\n\nwill iterate over the pairs (`1,t{1}`), (`2,t{2}`), ..., up to the first\ninteger key absent from the table.",
    "signature": "ipairs (t)"
  },
  "load": {
    "description": "# load (ld {, source {, mode {, env}}})\nLoads a chunk.\n\nIf `ld` is a string, the chunk is this string. If `ld` is a function,\n`load` calls it repeatedly to get the chunk pieces. Each call to `ld`\nmust return a string that concatenates with previous results. A return\nof an empty string, **nil**, or no value signals the end of the chunk.\n\nIf there are no syntactic errors, returns the compiled chunk as a\nfunction; otherwise, returns **nil** plus the error message.\n\nIf the resulting function has upvalues, the first upvalue is set to the\nvalue of `env`, if that parameter is given, or to the value of the\nglobal environment. (When you load a main chunk, the resulting function\nwill always have exactly one upvalue, the `_ENV` variable (see\n{§2.2}(#2.2)). When you load a binary chunk created from a function (see\n{`string.dump`}(#pdf-string.dump)), the resulting function can have\narbitrary upvalues.)\n\n`source` is used as the source of the chunk for error messages and debug\ninformation (see {§4.9}(#4.9)). When absent, it defaults to `ld`, if\n`ld` is a string, or to \"`=(load)`\" otherwise.\n\nThe string `mode` controls whether the chunk can be text or binary (that\nis, a precompiled chunk). It may be the string \"`b`\" (only binary\nchunks), \"`t`\" (only text chunks), or \"`bt`\" (both binary and text). The\ndefault is \"`bt`\".",
    "signature": "load (ld {, source {, mode {, env}}})"
  },
  "loadfile": {
    "description": "# loadfile ({filename {, mode {, env}}})\nSimilar to {`load`}(#pdf-load), but gets the chunk from file `filename`\nor from the standard input, if no file name is given.",
    "signature": "loadfile ({filename {, mode {, env}}})"
  },
  "next": {
    "description": "# next (table {, index})\nAllows a program to traverse all fields of a table. Its first argument\nis a table and its second argument is an index in this table. `next`\nreturns the next index of the table and its associated value. When\ncalled with **nil** as its second argument, `next` returns an initial\nindex and its associated value. When called with the last index, or with\n**nil** in an empty table, `next` returns **nil**. If the second\nargument is absent, then it is interpreted as **nil**. In particular,\nyou can use `next(t)` to check whether a table is empty.\n\nThe order in which the indices are enumerated is not specified, *even\nfor numeric indices*. (To traverse a table in numeric order, use a\nnumerical **for**.)\n\nThe behavior of `next` is undefined if, during the traversal, you assign\nany value to a non-existent field in the table. You may however modify\nexisting fields. In particular, you may clear existing fields.",
    "signature": "next (table {, index})"
  },
  "pairs": {
    "description": "# pairs (t)\nIf `t` has a metamethod `__pairs`, calls it with `t` as argument and\nreturns the first three results from the call.\n\nOtherwise, returns three values: the {`next`}(#pdf-next) function, the\ntable `t`, and **nil**, so that the construction\n\n         for k,v in pairs(t) do body end\n\nwill iterate over all key–value pairs of table `t`.\n\nSee function {`next`}(#pdf-next) for the caveats of modifying the table\nduring its traversal.",
    "signature": "pairs (t)"
  },
  "pcall": {
    "description": "# pcall (f {, arg1, ···})\nCalls function `f` with the given arguments in *protected mode*. This\nmeans that any error inside `f` is not propagated; instead, `pcall`\ncatches the error and returns a status code. Its first result is the\nstatus code (a boolean), which is true if the call succeeds without\nerrors. In such case, `pcall` also returns all results from the call,\nafter this first result. In case of any error, `pcall` returns **false**\nplus the error message.",
    "signature": "pcall (f {, arg1, ···})"
  },
  "print": {
    "description": "# print (···)\nReceives any number of arguments and prints their values to `stdout`,\nusing the {`tostring`}(#pdf-tostring) function to convert each argument\nto a string. `print` is not intended for formatted output, but only as a\nquick way to show a value, for instance for debugging. For complete\ncontrol over the output, use {`string.format`}(#pdf-string.format) and\n{`io.write`}(#pdf-io.write).",
    "signature": "print (···)"
  },
  "rawequal": {
    "description": "# rawequal (v1, v2)\nChecks whether `v1` is equal to `v2`, without invoking any metamethod.\nReturns a boolean.",
    "signature": "rawequal (v1, v2)"
  },
  "rawget": {
    "description": "# rawget (table, index)\nGets the real value of `table{index}`, without invoking any metamethod.\n`table` must be a table; `index` may be any value.",
    "signature": "rawget (table, index)"
  },
  "rawlen": {
    "description": "# rawlen (v)\nReturns the length of the object `v`, which must be a table or a string,\nwithout invoking any metamethod. Returns an integer number.",
    "signature": "rawlen (v)"
  },
  "rawset": {
    "description": "# rawset (table, index, value)\nSets the real value of `table{index}` to `value`, without invoking any\nmetamethod. `table` must be a table, `index` any value different from\n**nil** and NaN, and `value` any Lua value.\n\nThis function returns `table`.",
    "signature": "rawset (table, index, value)"
  },
  "select": {
    "description": "# select (index, ···)\nIf `index` is a number, returns all arguments after argument number\n`index`; a negative number indexes from the end (-1 is the last\nargument). Otherwise, `index` must be the string `\"#\"`, and `select`\nreturns the total number of extra arguments it received.",
    "signature": "select (index, ···)"
  },
  "setmetatable": {
    "description": "# setmetatable (table, metatable)\nSets the metatable for the given table. (You cannot change the metatable\nof other types from Lua, only from C.) If `metatable` is **nil**,\nremoves the metatable of the given table. If the original metatable has\na `\"__metatable\"` field, raises an error.\n\nThis function returns `table`.",
    "signature": "setmetatable (table, metatable)"
  },
  "tonumber": {
    "description": "# tonumber (e {, base})\nWhen called with no `base`, `tonumber` tries to convert its argument to\na number. If the argument is already a number or a string convertible to\na number (see {§3.4.2}(#3.4.2)), then `tonumber` returns this number;\notherwise, it returns **nil**.\n\nWhen called with `base`, then `e` should be a string to be interpreted\nas an integer numeral in that base. The base may be any integer between\n2 and 36, inclusive. In bases above 10, the letter '`A`' (in either\nupper or lower case) represents 10, '`B`' represents 11, and so forth,\nwith '`Z`' representing 35. If the string `e` is not a valid numeral in\nthe given base, the function returns **nil**.",
    "signature": "tonumber (e {, base})"
  },
  "tostring": {
    "description": "# tostring (v)\nReceives a value of any type and converts it to a string in a reasonable\nformat. (For complete control of how numbers are converted, use\n{`string.format`}(#pdf-string.format).)\n\nIf the metatable of `v` has a `\"__tostring\"` field, then `tostring`\ncalls the corresponding value with `v` as argument, and uses the result\nof the call as its result.",
    "signature": "tostring (v)"
  },
  "type": {
    "description": "# type (v)\nReturns the type of its only argument, coded as a string. The possible\nresults of this function are \"`nil`\" (a string, not the value **nil**),\n\"`number`\", \"`string`\", \"`boolean`\", \"`table`\", \"`function`\",\n\"`thread`\", and \"`userdata`\".",
    "signature": "type (v)"
  },
  "_VERSION": {
    "description": "# _VERSION\nA global variable (not a function) that holds a string containing the\ncurrent interpreter version. The current contents of this variable is\n\"`Lua 5.2`\".",
    "signature": "_VERSION"
  },
  "xpcall": {
    "description": "# xpcall (f, msgh {, arg1, ···})\nThis function is similar to {`pcall`}(#pdf-pcall), except that it sets a\nnew message handler `msgh`.\n\n6.2 – Coroutine Manipulation\n----------------------------\n\nThe operations related to coroutines comprise a sub-library of the basic\nlibrary and come inside the table `coroutine`. See {§2.6}(#2.6) for a\ngeneral description of coroutines.",
    "signature": "xpcall (f, msgh {, arg1, ···})"
  },
  "coroutine": {
    "create": {
      "description": "# coroutine.create (f)\nCreates a new coroutine, with body `f`. `f` must be a Lua function.\nReturns this new coroutine, an object with type `\"thread\"`.",
      "signature": "coroutine.create (f)"
    },
    "resume": {
      "description": "# coroutine.resume (co {, val1, ···})\nStarts or continues the execution of coroutine `co`. The first time you\nresume a coroutine, it starts running its body. The values `val1`, ...\nare passed as the arguments to the body function. If the coroutine has\nyielded, `resume` restarts it; the values `val1`, ... are passed as the\nresults from the yield.\n\nIf the coroutine runs without any errors, `resume` returns **true** plus\nany values passed to `yield` (if the coroutine yields) or any values\nreturned by the body function (if the coroutine terminates). If there is\nany error, `resume` returns **false** plus the error message.",
      "signature": "coroutine.resume (co {, val1, ···})"
    },
    "running": {
      "description": "# coroutine.running ()\nReturns the running coroutine plus a boolean, true when the running\ncoroutine is the main one.",
      "signature": "coroutine.running ()"
    },
    "status": {
      "description": "# coroutine.status (co)\nReturns the status of coroutine `co`, as a string: `\"running\"`, if the\ncoroutine is running (that is, it called `status`); `\"suspended\"`, if\nthe coroutine is suspended in a call to `yield`, or if it has not\nstarted running yet; `\"normal\"` if the coroutine is active but not\nrunning (that is, it has resumed another coroutine); and `\"dead\"` if the\ncoroutine has finished its body function, or if it has stopped with an\nerror.",
      "signature": "coroutine.status (co)"
    },
    "wrap": {
      "description": "# coroutine.wrap (f)\nCreates a new coroutine, with body `f`. `f` must be a Lua function.\nReturns a function that resumes the coroutine each time it is called.\nAny arguments passed to the function behave as the extra arguments to\n`resume`. Returns the same values returned by `resume`, except the first\nboolean. In case of error, propagates the error.",
      "signature": "coroutine.wrap (f)"
    },
    "yield": {
      "description": "# coroutine.yield (···)\nSuspends the execution of the calling coroutine. Any arguments to\n`yield` are passed as extra results to `resume`.\n\n6.3 – Modules\n-------------\n\nThe package library provides basic facilities for loading modules in\nLua. It exports one function directly in the global environment:\n{`require`}(#pdf-require). Everything else is exported in a table\n`package`.",
      "signature": "coroutine.yield (···)"
    }
  },
  "require": {
    "description": "# require (modname)\nLoads the given module. The function starts by looking into the\n{`package.loaded`}(#pdf-package.loaded) table to determine whether\n`modname` is already loaded. If it is, then `require` returns the value\nstored at `package.loaded{modname}`. Otherwise, it tries to find a\n*loader* for the module.\n\nTo find a loader, `require` is guided by the\n{`package.searchers`}(#pdf-package.searchers) sequence. By changing this\nsequence, we can change how `require` looks for a module. The following\nexplanation is based on the default configuration for\n{`package.searchers`}(#pdf-package.searchers).\n\nFirst `require` queries `package.preload{modname}`. If it has a value,\nthis value (which should be a function) is the loader. Otherwise\n`require` searches for a Lua loader using the path stored in\n{`package.path`}(#pdf-package.path). If that also fails, it searches for\na C loader using the path stored in\n{`package.cpath`}(#pdf-package.cpath). If that also fails, it tries an\n*all-in-one* loader (see {`package.searchers`}(#pdf-package.searchers)).\n\nOnce a loader is found, `require` calls the loader with two arguments:\n`modname` and an extra value dependent on how it got the loader. (If the\nloader came from a file, this extra value is the file name.) If the\nloader returns any non-nil value, `require` assigns the returned value\nto `package.loaded{modname}`. If the loader does not return a non-nil\nvalue and has not assigned any value to `package.loaded{modname}`, then\n`require` assigns **true** to this entry. In any case, `require` returns\nthe final value of `package.loaded{modname}`.\n\nIf there is any error loading or running the module, or if it cannot\nfind any loader for the module, then `require` raises an error.",
    "signature": "require (modname)"
  },
  "package": {
    "config": {
      "description": "# package.config\nA string describing some compile-time configurations for packages. This\nstring is a sequence of lines:\n\n-   The first line is the directory separator string. Default is '`\\`'\n    for Windows and '`/`' for all other systems.\n-   The second line is the character that separates templates in a path.\n    Default is '`;`'.\n-   The third line is the string that marks the substitution points in a\n    template. Default is '`?`'.\n-   The fourth line is a string that, in a path in Windows, is replaced\n    by the executable's directory. Default is '`!`'.\n-   The fifth line is a mark to ignore all text before it when building\n    the `luaopen_` function name. Default is '`-`'.",
      "signature": "package.config"
    },
    "cpath": {
      "description": "# package.cpath\nThe path used by {`require`}(#pdf-require) to search for a C loader.\n\nLua initializes the C path {`package.cpath`}(#pdf-package.cpath) in the\nsame way it initializes the Lua path\n{`package.path`}(#pdf-package.path), using the environment variable\n`LUA_CPATH_5_2` or the environment variable `LUA_CPATH` or a default\npath defined in `luaconf.h`.",
      "signature": "package.cpath"
    },
    "loaded": {
      "description": "# package.loaded\nA table used by {`require`}(#pdf-require) to control which modules are\nalready loaded. When you require a module `modname` and\n`package.loaded{modname}` is not false, {`require`}(#pdf-require) simply\nreturns the value stored there.\n\nThis variable is only a reference to the real table; assignments to this\nvariable do not change the table used by {`require`}(#pdf-require).",
      "signature": "package.loaded"
    },
    "loadlib": {
      "description": "# package.loadlib (libname, funcname)\nDynamically links the host program with the C library `libname`.\n\nIf `funcname` is \"`*`\", then it only links with the library, making the\nsymbols exported by the library available to other dynamically linked\nlibraries. Otherwise, it looks for a function `funcname` inside the\nlibrary and returns this function as a C function. So, `funcname` must\nfollow the {`lua_CFunction`}(#lua_CFunction) prototype (see\n{`lua_CFunction`}(#lua_CFunction)).\n\nThis is a low-level function. It completely bypasses the package and\nmodule system. Unlike {`require`}(#pdf-require), it does not perform any\npath searching and does not automatically adds extensions. `libname`\nmust be the complete file name of the C library, including if necessary\na path and an extension. `funcname` must be the exact name exported by\nthe C library (which may depend on the C compiler and linker used).\n\nThis function is not supported by Standard C. As such, it is only\navailable on some platforms (Windows, Linux, Mac OS X, Solaris, BSD,\nplus other Unix systems that support the `dlfcn` standard).",
      "signature": "package.loadlib (libname, funcname)"
    },
    "path": {
      "description": "# package.path\nThe path used by {`require`}(#pdf-require) to search for a Lua loader.\n\nAt start-up, Lua initializes this variable with the value of the\nenvironment variable `LUA_PATH_5_2` or the environment variable\n`LUA_PATH` or with a default path defined in `luaconf.h`, if those\nenvironment variables are not defined. Any \"`;;`\" in the value of the\nenvironment variable is replaced by the default path.",
      "signature": "package.path"
    },
    "preload": {
      "description": "# package.preload\nA table to store loaders for specific modules (see\n{`require`}(#pdf-require)).\n\nThis variable is only a reference to the real table; assignments to this\nvariable do not change the table used by {`require`}(#pdf-require).",
      "signature": "package.preload"
    },
    "searchers": {
      "description": "# package.searchers\nA table used by {`require`}(#pdf-require) to control how to load\nmodules.\n\nEach entry in this table is a *searcher function*. When looking for a\nmodule, {`require`}(#pdf-require) calls each of these searchers in\nascending order, with the module name (the argument given to\n{`require`}(#pdf-require)) as its sole parameter. The function can\nreturn another function (the module *loader*) plus an extra value that\nwill be passed to that loader, or a string explaining why it did not\nfind that module (or **nil** if it has nothing to say).\n\nLua initializes this table with four searcher functions.\n\nThe first searcher simply looks for a loader in the\n{`package.preload`}(#pdf-package.preload) table.\n\nThe second searcher looks for a loader as a Lua library, using the path\nstored at {`package.path`}(#pdf-package.path). The search is done as\ndescribed in function {`package.searchpath`}(#pdf-package.searchpath).\n\nThe third searcher looks for a loader as a C library, using the path\ngiven by the variable {`package.cpath`}(#pdf-package.cpath). Again, the\nsearch is done as described in function\n{`package.searchpath`}(#pdf-package.searchpath). For instance, if the\nC path is the string\n\n         \"./?.so;./?.dll;/usr/local/?/init.so\"\n\nthe searcher for module `foo` will try to open the files `./foo.so`,\n`./foo.dll`, and `/usr/local/foo/init.so`, in that order. Once it finds\na C library, this searcher first uses a dynamic link facility to link\nthe application with the library. Then it tries to find a C function\ninside the library to be used as the loader. The name of this C function\nis the string \"`luaopen_`\" concatenated with a copy of the module name\nwhere each dot is replaced by an underscore. Moreover, if the module\nname has a hyphen, its prefix up to (and including) the first hyphen is\nremoved. For instance, if the module name is `a.v1-b.c`, the function\nname will be `luaopen_b_c`.\n\nThe fourth searcher tries an *all-in-one loader*. It searches the C path\nfor a library for the root name of the given module. For instance, when\nrequiring `a.b.c`, it will search for a C library for `a`. If found, it\nlooks into it for an open function for the submodule; in our example,\nthat would be `luaopen_a_b_c`. With this facility, a package can pack\nseveral C submodules into one single library, with each submodule\nkeeping its original open function.\n\nAll searchers except the first one (preload) return as the extra value\nthe file name where the module was found, as returned by\n{`package.searchpath`}(#pdf-package.searchpath). The first searcher\nreturns no extra value.",
      "signature": "package.searchers"
    },
    "searchpath": {
      "description": "# package.searchpath (name, path {, sep {, rep}})\nSearches for the given `name` in the given `path`.\n\nA path is a string containing a sequence of *templates* separated by\nsemicolons. For each template, the function replaces each interrogation\nmark (if any) in the template with a copy of `name` wherein all\noccurrences of `sep` (a dot, by default) were replaced by `rep` (the\nsystem's directory separator, by default), and then tries to open the\nresulting file name.\n\nFor instance, if the path is the string\n\n         \"./?.lua;./?.lc;/usr/local/?/init.lua\"\n\nthe search for the name `foo.a` will try to open the files\n`./foo/a.lua`, `./foo/a.lc`, and `/usr/local/foo/a/init.lua`, in that\norder.\n\nReturns the resulting name of the first file that it can open in read\nmode (after closing the file), or **nil** plus an error message if none\nsucceeds. (This error message lists all file names it tried to open.)\n\n6.4 – String Manipulation\n-------------------------\n\nThis library provides generic functions for string manipulation, such as\nfinding and extracting substrings, and pattern matching. When indexing a\nstring in Lua, the first character is at position 1 (not at 0, as in C).\nIndices are allowed to be negative and are interpreted as indexing\nbackwards, from the end of the string. Thus, the last character is at\nposition -1, and so on.\n\nThe string library provides all its functions inside the table `string`.\nIt also sets a metatable for strings where the `__index` field points to\nthe `string` table. Therefore, you can use the string functions in\nobject-oriented style. For instance, `string.byte(s,i)` can be written\nas `s:byte(i)`.\n\nThe string library assumes one-byte character encodings.",
      "signature": "package.searchpath (name, path {, sep {, rep}})"
    }
  },
  "string": {
    "byte": {
      "description": "# string.byte (s {, i {, j}})\nReturns the internal numerical codes of the characters `s{i}`, `s{i+1}`,\n..., `s{j}`. The default value for `i` is 1; the default value for `j`\nis `i`. These indices are corrected following the same rules of function\n{`string.sub`}(#pdf-string.sub).\n\nNumerical codes are not necessarily portable across platforms.",
      "signature": "string.byte (s {, i {, j}})"
    },
    "char": {
      "description": "# string.char (···)\nReceives zero or more integers. Returns a string with length equal to\nthe number of arguments, in which each character has the internal\nnumerical code equal to its corresponding argument.\n\nNumerical codes are not necessarily portable across platforms.",
      "signature": "string.char (···)"
    },
    "dump": {
      "description": "# string.dump (function)\nReturns a string containing a binary representation of the given\nfunction, so that a later {`load`}(#pdf-load) on this string returns a\ncopy of the function (but with new upvalues).",
      "signature": "string.dump (function)"
    },
    "find": {
      "description": "# string.find (s, pattern {, init {, plain}})\nLooks for the first match of `pattern` in the string `s`. If it finds a\nmatch, then `find` returns the indices of `s` where this occurrence\nstarts and ends; otherwise, it returns **nil**. A third, optional\nnumerical argument `init` specifies where to start the search; its\ndefault value is 1 and can be negative. A value of **true** as a fourth,\noptional argument `plain` turns off the pattern matching facilities, so\nthe function does a plain \"find substring\" operation, with no characters\nin `pattern` being considered magic. Note that if `plain` is given, then\n`init` must be given as well.\n\nIf the pattern has captures, then in a successful match the captured\nvalues are also returned, after the two indices.",
      "signature": "string.find (s, pattern {, init {, plain}})"
    },
    "format": {
      "description": "# string.format (formatstring, ···)\nReturns a formatted version of its variable number of arguments\nfollowing the description given in its first argument (which must be a\nstring). The format string follows the same rules as the ANSI C function\n`sprintf`. The only differences are that the options/modifiers `*`, `h`,\n`L`, `l`, `n`, and `p` are not supported and that there is an extra\noption, `q`. The `q` option formats a string between double quotes,\nusing escape sequences when necessary to ensure that it can safely be\nread back by the Lua interpreter. For instance, the call\n\n         string.format('%q', 'a string with \"quotes\" and \\n new line')\n\nmay produce the string:\n\n         \"a string with \\\"quotes\\\" and \\\n          new line\"\n\nOptions `A` and `a` (when available), `E`, `e`, `f`, `G`, and `g` all\nexpect a number as argument. Options `c`, `d`, `i`, `o`, `u`, `X`, and\n`x` also expect a number, but the range of that number may be limited by\nthe underlying C implementation. For options `o`, `u`, `X`, and `x`, the\nnumber cannot be negative. Option `q` expects a string; option `s`\nexpects a string without embedded zeros. If the argument to option `s`\nis not a string, it is converted to one following the same rules of\n{`tostring`}(#pdf-tostring).",
      "signature": "string.format (formatstring, ···)"
    },
    "gmatch": {
      "description": "# string.gmatch (s, pattern)\nReturns an iterator function that, each time it is called, returns the\nnext captures from `pattern` over the string `s`. If `pattern` specifies\nno captures, then the whole match is produced in each call.\n\nAs an example, the following loop will iterate over all the words from\nstring `s`, printing one per line:\n\n         s = \"hello world from Lua\"\n         for w in string.gmatch(s, \"%a+\") do\n           print(w)\n         end\n\nThe next example collects all pairs `key=value` from the given string\ninto a table:\n\n         t = {}\n         s = \"from=world, to=Lua\"\n         for k, v in string.gmatch(s, \"(%w+)=(%w+)\") do\n           t{k} = v\n         end\n\nFor this function, a caret '`^`' at the start of a pattern does not work\nas an anchor, as this would prevent the iteration.",
      "signature": "string.gmatch (s, pattern)"
    },
    "gsub": {
      "description": "# string.gsub (s, pattern, repl {, n})\nReturns a copy of `s` in which all (or the first `n`, if given)\noccurrences of the `pattern` have been replaced by a replacement string\nspecified by `repl`, which can be a string, a table, or a function.\n`gsub` also returns, as its second value, the total number of matches\nthat occurred. The name `gsub` comes from *Global SUBstitution*.\n\nIf `repl` is a string, then its value is used for replacement. The\ncharacter `%` works as an escape character: any sequence in `repl` of\nthe form `%d`, with *d* between 1 and 9, stands for the value of the\n*d*-th captured substring. The sequence `%0` stands for the whole match.\nThe sequence `%%` stands for a single `%`.\n\nIf `repl` is a table, then the table is queried for every match, using\nthe first capture as the key.\n\nIf `repl` is a function, then this function is called every time a match\noccurs, with all captured substrings passed as arguments, in order.\n\nIn any case, if the pattern specifies no captures, then it behaves as if\nthe whole pattern was inside a capture.\n\nIf the value returned by the table query or by the function call is a\nstring or a number, then it is used as the replacement string;\notherwise, if it is **false** or **nil**, then there is no replacement\n(that is, the original match is kept in the string).\n\nHere are some examples:\n\n         x = string.gsub(\"hello world\", \"(%w+)\", \"%1 %1\")\n         --> x=\"hello hello world world\"\n         \n         x = string.gsub(\"hello world\", \"%w+\", \"%0 %0\", 1)\n         --> x=\"hello hello world\"\n         \n         x = string.gsub(\"hello world from Lua\", \"(%w+)%s*(%w+)\", \"%2 %1\")\n         --> x=\"world hello Lua from\"\n         \n         x = string.gsub(\"home = $HOME, user = $USER\", \"%$(%w+)\", os.getenv)\n         --> x=\"home = /home/roberto, user = roberto\"\n         \n         x = string.gsub(\"4+5 = $return 4+5$\", \"%$(.-)%$\", function (s)\n               return load(s)()\n             end)\n         --> x=\"4+5 = 9\"\n         \n         local t = {name=\"lua\", version=\"5.2\"}\n         x = string.gsub(\"$name-$version.tar.gz\", \"%$(%w+)\", t)\n         --> x=\"lua-5.2.tar.gz\"",
      "signature": "string.gsub (s, pattern, repl {, n})"
    },
    "len": {
      "description": "# string.len (s)\nReceives a string and returns its length. The empty string `\"\"` has\nlength 0. Embedded zeros are counted, so `\"a\\000bc\\000\"` has length 5.",
      "signature": "string.len (s)"
    },
    "lower": {
      "description": "# string.lower (s)\nReceives a string and returns a copy of this string with all uppercase\nletters changed to lowercase. All other characters are left unchanged.\nThe definition of what an uppercase letter is depends on the current\nlocale.",
      "signature": "string.lower (s)"
    },
    "match": {
      "description": "# string.match (s, pattern {, init})\nLooks for the first *match* of `pattern` in the string `s`. If it finds\none, then `match` returns the captures from the pattern; otherwise it\nreturns **nil**. If `pattern` specifies no captures, then the whole\nmatch is returned. A third, optional numerical argument `init` specifies\nwhere to start the search; its default value is 1 and can be negative.",
      "signature": "string.match (s, pattern {, init})"
    },
    "rep": {
      "description": "# string.rep (s, n {, sep})\nReturns a string that is the concatenation of `n` copies of the string\n`s` separated by the string `sep`. The default value for `sep` is the\nempty string (that is, no separator).",
      "signature": "string.rep (s, n {, sep})"
    },
    "reverse": {
      "description": "# string.reverse (s)\nReturns a string that is the string `s` reversed.",
      "signature": "string.reverse (s)"
    },
    "sub": {
      "description": "# string.sub (s, i {, j})\nReturns the substring of `s` that starts at `i` and continues until `j`;\n`i` and `j` can be negative. If `j` is absent, then it is assumed to be\nequal to -1 (which is the same as the string length). In particular, the\ncall `string.sub(s,1,j)` returns a prefix of `s` with length `j`, and\n`string.sub(s, -i)` returns a suffix of `s` with length `i`.\n\nIf, after the translation of negative indices, `i` is less than 1, it is\ncorrected to 1. If `j` is greater than the string length, it is\ncorrected to that length. If, after these corrections, `i` is greater\nthan `j`, the function returns the empty string.",
      "signature": "string.sub (s, i {, j})"
    },
    "upper": {
      "description": "# string.upper (s)\nReceives a string and returns a copy of this string with all lowercase\nletters changed to uppercase. All other characters are left unchanged.\nThe definition of what a lowercase letter is depends on the current\nlocale.\n\n### 6.4.1 – Patterns\n\n#### Character Class:\n\nA *character class* is used to represent a set of characters. The\nfollowing combinations are allowed in describing a character class:\n\n-   ***x*:** (where *x* is not one of the *magic characters*\n    `^$()%.{}*+-?`) represents the character *x* itself.\n-   **`.`:** (a dot) represents all characters.\n-   **`%a`:** represents all letters.\n-   **`%c`:** represents all control characters.\n-   **`%d`:** represents all digits.\n-   **`%g`:** represents all printable characters except space.\n-   **`%l`:** represents all lowercase letters.\n-   **`%p`:** represents all punctuation characters.\n-   **`%s`:** represents all space characters.\n-   **`%u`:** represents all uppercase letters.\n-   **`%w`:** represents all alphanumeric characters.\n-   **`%x`:** represents all hexadecimal digits.\n-   **`%x`:** (where *x* is any non-alphanumeric character) represents\n    the character *x*. This is the standard way to escape the magic\n    characters. Any punctuation character (even the non magic) can be\n    preceded by a '`%`' when used to represent itself in a pattern.\n-   **`{set}`:** represents the class which is the union of all\n    characters in *set*. A range of characters can be specified by\n    separating the end characters of the range, in ascending order, with\n    a '`-`', All classes `%`*x* described above can also be used as\n    components in *set*. All other characters in *set* represent\n    themselves. For example, `{%w_}` (or `{_%w}`) represents all\n    alphanumeric characters plus the underscore, `{0-7}` represents the\n    octal digits, and `{0-7%l%-}` represents the octal digits plus the\n    lowercase letters plus the '`-`' character.\n    The interaction between ranges and classes is not defined.\n    Therefore, patterns like `{%a-z}` or `{a-%%}` have no meaning.\n-   **`{^set}`:** represents the complement of *set*, where *set* is\n    interpreted as above.\n\nFor all classes represented by single letters (`%a`, `%c`, etc.), the\ncorresponding uppercase letter represents the complement of the class.\nFor instance, `%S` represents all non-space characters.\n\nThe definitions of letter, space, and other character groups depend on\nthe current locale. In particular, the class `{a-z}` may not be\nequivalent to `%l`.\n\n#### Pattern Item:\n\nA *pattern item* can be\n\n-   a single character class, which matches any single character in the\n    class;\n-   a single character class followed by '`*`', which matches 0 or more\n    repetitions of characters in the class. These repetition items will\n    always match the longest possible sequence;\n-   a single character class followed by '`+`', which matches 1 or more\n    repetitions of characters in the class. These repetition items will\n    always match the longest possible sequence;\n-   a single character class followed by '`-`', which also matches 0 or\n    more repetitions of characters in the class. Unlike '`*`', these\n    repetition items will always match the shortest possible sequence;\n-   a single character class followed by '`?`', which matches 0 or 1\n    occurrence of a character in the class;\n-   `%n`, for *n* between 1 and 9; such item matches a substring equal\n    to the *n*-th captured string (see below);\n-   `%bxy`, where *x* and *y* are two distinct characters; such item\n    matches strings that start with *x*, end with *y*, and where the *x*\n    and *y* are *balanced*. This means that, if one reads the string\n    from left to right, counting *+1* for an *x* and *-1* for a *y*, the\n    ending *y* is the first *y* where the count reaches 0. For instance,\n    the item `%b()` matches expressions with balanced parentheses.\n-   `%f{set}`, a *frontier pattern*; such item matches an empty string\n    at any position such that the next character belongs to *set* and\n    the previous character does not belong to *set*. The set *set* is\n    interpreted as previously described. The beginning and the end of\n    the subject are handled as if they were the character '`\\0`'.\n\n#### Pattern:\n\nA *pattern* is a sequence of pattern items. A caret '`^`' at the\nbeginning of a pattern anchors the match at the beginning of the subject\nstring. A '`$`' at the end of a pattern anchors the match at the end of\nthe subject string. At other positions, '`^`' and '`$`' have no special\nmeaning and represent themselves.\n\n#### Captures:\n\nA pattern can contain sub-patterns enclosed in parentheses; they\ndescribe *captures*. When a match succeeds, the substrings of the\nsubject string that match captures are stored (*captured*) for future\nuse. Captures are numbered according to their left parentheses. For\ninstance, in the pattern `\"(a*(.)%w(%s*))\"`, the part of the string\nmatching `\"a*(.)%w(%s*)\"` is stored as the first capture (and therefore\nhas number 1); the character matching \"`.`\" is captured with number 2,\nand the part matching \"`%s*`\" has number 3.\n\nAs a special case, the empty capture `()` captures the current string\nposition (a number). For instance, if we apply the pattern `\"()aa()\"` on\nthe string `\"flaaap\"`, there will be two captures: 3 and 5.\n\n6.5 – Table Manipulation\n------------------------\n\nThis library provides generic functions for table manipulation. It\nprovides all its functions inside the table `table`.\n\nRemember that, whenever an operation needs the length of a table, the\ntable should be a proper sequence or have a `__len` metamethod (see\n{§3.4.6}(#3.4.6)). All functions ignore non-numeric keys in tables given\nas arguments.\n\nFor performance reasons, all table accesses (get/set) performed by these\nfunctions are raw.",
      "signature": "string.upper (s)"
    }
  },
  "table": {
    "concat": {
      "description": "# table.concat (list {, sep {, i {, j}}})\nGiven a list where all elements are strings or numbers, returns the\nstring `list{i}..sep..list{i+1} ··· sep..list{j}`. The default value for\n`sep` is the empty string, the default for `i` is 1, and the default for\n`j` is `#list`. If `i` is greater than `j`, returns the empty string.",
      "signature": "table.concat (list {, sep {, i {, j}}})"
    },
    "insert": {
      "description": "# table.insert (list, {pos,} value)\nInserts element `value` at position `pos` in `list`, shifting up the\nelements `list{pos}, list{pos+1}, ···, list{#list}`. The default value\nfor `pos` is `#list+1`, so that a call `table.insert(t,x)` inserts `x`\nat the end of list `t`.",
      "signature": "table.insert (list, {pos,} value)"
    },
    "pack": {
      "description": "# table.pack (···)\nReturns a new table with all parameters stored into keys 1, 2, etc. and\nwith a field \"`n`\" with the total number of parameters. Note that the\nresulting table may not be a sequence.",
      "signature": "table.pack (···)"
    },
    "remove": {
      "description": "# table.remove (list {, pos})\nRemoves from `list` the element at position `pos`, returning the value\nof the removed element. When `pos` is an integer between 1 and `#list`,\nit shifts down the elements `list{pos+1}, list{pos+2}, ···, list{#list}`\nand erases element `list{#list}`; The index `pos` can also be 0 when\n`#list` is 0, or `#list + 1`; in those cases, the function erases the\nelement `list{pos}`.\n\nThe default value for `pos` is `#list`, so that a call `table.remove(t)`\nremoves the last element of list `t`.",
      "signature": "table.remove (list {, pos})"
    },
    "sort": {
      "description": "# table.sort (list {, comp})\nSorts list elements in a given order, *in-place*, from `list{1}` to\n`list{#list}`. If `comp` is given, then it must be a function that\nreceives two list elements and returns true when the first element must\ncome before the second in the final order (so that\n`not comp(list{i+1},list{i})` will be true after the sort). If `comp` is\nnot given, then the standard Lua operator `<` is used instead.\n\nThe sort algorithm is not stable; that is, elements considered equal by\nthe given order may have their relative positions changed by the sort.",
      "signature": "table.sort (list {, comp})"
    },
    "unpack": {
      "description": "# table.unpack (list {, i {, j}})\nReturns the elements from the given table. This function is equivalent\nto\n\n         return list{i}, list{i+1}, ···, list{j}\n\nBy default, `i` is 1 and `j` is `#list`.\n\n6.6 – Mathematical Functions\n----------------------------\n\nThis library is an interface to the standard C math library. It provides\nall its functions inside the table `math`.",
      "signature": "table.unpack (list {, i {, j}})"
    }
  },
  "math": {
    "abs": {
      "description": "# math.abs (x)\nReturns the absolute value of `x`.",
      "signature": "math.abs (x)"
    },
    "acos": {
      "description": "# math.acos (x)\nReturns the arc cosine of `x` (in radians).",
      "signature": "math.acos (x)"
    },
    "asin": {
      "description": "# math.asin (x)\nReturns the arc sine of `x` (in radians).",
      "signature": "math.asin (x)"
    },
    "atan": {
      "description": "# math.atan (x)\nReturns the arc tangent of `x` (in radians).",
      "signature": "math.atan (x)"
    },
    "atan2": {
      "description": "# math.atan2 (y, x)\nReturns the arc tangent of `y/x` (in radians), but uses the signs of\nboth parameters to find the quadrant of the result. (It also handles\ncorrectly the case of `x` being zero.)",
      "signature": "math.atan2 (y, x)"
    },
    "ceil": {
      "description": "# math.ceil (x)\nReturns the smallest integer larger than or equal to `x`.",
      "signature": "math.ceil (x)"
    },
    "cos": {
      "description": "# math.cos (x)\nReturns the cosine of `x` (assumed to be in radians).",
      "signature": "math.cos (x)"
    },
    "cosh": {
      "description": "# math.cosh (x)\nReturns the hyperbolic cosine of `x`.",
      "signature": "math.cosh (x)"
    },
    "deg": {
      "description": "# math.deg (x)\nReturns the angle `x` (given in radians) in degrees.",
      "signature": "math.deg (x)"
    },
    "exp": {
      "description": "# math.exp (x)\nReturns the value *e^x^*.",
      "signature": "math.exp (x)"
    },
    "floor": {
      "description": "# math.floor (x)\nReturns the largest integer smaller than or equal to `x`.",
      "signature": "math.floor (x)"
    },
    "fmod": {
      "description": "# math.fmod (x, y)\nReturns the remainder of the division of `x` by `y` that rounds the\nquotient towards zero.",
      "signature": "math.fmod (x, y)"
    },
    "frexp": {
      "description": "# math.frexp (x)\nReturns `m` and `e` such that *x = m2^e^*, `e` is an integer and the\nabsolute value of `m` is in the range *{0.5, 1)* (or zero when `x` is\nzero).",
      "signature": "math.frexp (x)"
    },
    "huge": {
      "description": "# math.huge\nThe value `HUGE_VAL`, a value larger than or equal to any other\nnumerical value.",
      "signature": "math.huge"
    },
    "ldexp": {
      "description": "# math.ldexp (m, e)\nReturns *m2^e^* (`e` should be an integer).",
      "signature": "math.ldexp (m, e)"
    },
    "log": {
      "description": "# math.log (x {, base})\nReturns the logarithm of `x` in the given base. The default for `base`\nis *e* (so that the function returns the natural logarithm of `x`).",
      "signature": "math.log (x {, base})"
    },
    "max": {
      "description": "# math.max (x, ···)\nReturns the maximum value among its arguments.",
      "signature": "math.max (x, ···)"
    },
    "min": {
      "description": "# math.min (x, ···)\nReturns the minimum value among its arguments.",
      "signature": "math.min (x, ···)"
    },
    "modf": {
      "description": "# math.modf (x)\nReturns two numbers, the integral part of `x` and the fractional part of\n`x`.",
      "signature": "math.modf (x)"
    },
    "pi": {
      "description": "# math.pi\nThe value of *π*.",
      "signature": "math.pi"
    },
    "pow": {
      "description": "# math.pow (x, y)\nReturns *x^y^*. (You can also use the expression `x^y` to compute this\nvalue.)",
      "signature": "math.pow (x, y)"
    },
    "rad": {
      "description": "# math.rad (x)\nReturns the angle `x` (given in degrees) in radians.",
      "signature": "math.rad (x)"
    },
    "random": {
      "description": "# math.random ({m {, n}})\nThis function is an interface to the simple pseudo-random generator\nfunction `rand` provided by Standard C. (No guarantees can be given for\nits statistical properties.)\n\nWhen called without arguments, returns a uniform pseudo-random real\nnumber in the range *{0,1)*. When called with an integer number `m`,\n`math.random` returns a uniform pseudo-random integer in the range *{1,\nm}*. When called with two integer numbers `m` and `n`, `math.random`\nreturns a uniform pseudo-random integer in the range *{m, n}*.",
      "signature": "math.random ({m {, n}})"
    },
    "randomseed": {
      "description": "# math.randomseed (x)\nSets `x` as the \"seed\" for the pseudo-random generator: equal seeds\nproduce equal sequences of numbers.",
      "signature": "math.randomseed (x)"
    },
    "sin": {
      "description": "# math.sin (x)\nReturns the sine of `x` (assumed to be in radians).",
      "signature": "math.sin (x)"
    },
    "sinh": {
      "description": "# math.sinh (x)\nReturns the hyperbolic sine of `x`.",
      "signature": "math.sinh (x)"
    },
    "sqrt": {
      "description": "# math.sqrt (x)\nReturns the square root of `x`. (You can also use the expression `x^0.5`\nto compute this value.)",
      "signature": "math.sqrt (x)"
    },
    "tan": {
      "description": "# math.tan (x)\nReturns the tangent of `x` (assumed to be in radians).",
      "signature": "math.tan (x)"
    },
    "tanh": {
      "description": "# math.tanh (x)\nReturns the hyperbolic tangent of `x`.\n\n6.7 – Bitwise Operations\n------------------------\n\nThis library provides bitwise operations. It provides all its functions\ninside the table `bit32`.\n\nUnless otherwise stated, all functions accept numeric arguments in the\nrange *(-2^51^,+2^51^)*; each argument is normalized to the remainder of\nits division by *2^32^* and truncated to an integer (in some unspecified\nway), so that its final value falls in the range *{0,2^32^ - 1}*.\nSimilarly, all results are in the range *{0,2^32^ - 1}*. Note that\n`bit32.bnot(0)` is `0xFFFFFFFF`, which is different from `-1`.",
      "signature": "math.tanh (x)"
    }
  },
  "bit32": {
    "arshift": {
      "description": "# bit32.arshift (x, disp)\nReturns the number `x` shifted `disp` bits to the right. The number\n`disp` may be any representable integer. Negative displacements shift to\nthe left.\n\nThis shift operation is what is called arithmetic shift. Vacant bits on\nthe left are filled with copies of the higher bit of `x`; vacant bits on\nthe right are filled with zeros. In particular, displacements with\nabsolute values higher than 31 result in zero or `0xFFFFFFFF` (all\noriginal bits are shifted out).",
      "signature": "bit32.arshift (x, disp)"
    },
    "band": {
      "description": "# bit32.band (···)\nReturns the bitwise *and* of its operands.",
      "signature": "bit32.band (···)"
    },
    "bnot": {
      "description": "# bit32.bnot (x)\nReturns the bitwise negation of `x`. For any integer `x`, the following\nidentity holds:\n\n         assert(bit32.bnot(x) == (-1 - x) % 2^32)",
      "signature": "bit32.bnot (x)"
    },
    "bor": {
      "description": "# bit32.bor (···)\nReturns the bitwise *or* of its operands.",
      "signature": "bit32.bor (···)"
    },
    "btest": {
      "description": "# bit32.btest (···)\nReturns a boolean signaling whether the bitwise *and* of its operands is\ndifferent from zero.",
      "signature": "bit32.btest (···)"
    },
    "bxor": {
      "description": "# bit32.bxor (···)\nReturns the bitwise *exclusive or* of its operands.",
      "signature": "bit32.bxor (···)"
    },
    "extract": {
      "description": "# bit32.extract (n, field {, width})\nReturns the unsigned number formed by the bits `field` to\n`field + width - 1` from `n`. Bits are numbered from 0 (least\nsignificant) to 31 (most significant). All accessed bits must be in the\nrange *{0, 31}*.\n\nThe default for `width` is 1.",
      "signature": "bit32.extract (n, field {, width})"
    },
    "replace": {
      "description": "# bit32.replace (n, v, field {, width})\nReturns a copy of `n` with the bits `field` to `field + width - 1`\nreplaced by the value `v`. See {`bit32.extract`}(#pdf-bit32.extract) for\ndetails about `field` and `width`.",
      "signature": "bit32.replace (n, v, field {, width})"
    },
    "lrotate": {
      "description": "# bit32.lrotate (x, disp)\nReturns the number `x` rotated `disp` bits to the left. The number\n`disp` may be any representable integer.\n\nFor any valid displacement, the following identity holds:\n\n         assert(bit32.lrotate(x, disp) == bit32.lrotate(x, disp % 32))\n\nIn particular, negative displacements rotate to the right.",
      "signature": "bit32.lrotate (x, disp)"
    },
    "lshift": {
      "description": "# bit32.lshift (x, disp)\nReturns the number `x` shifted `disp` bits to the left. The number\n`disp` may be any representable integer. Negative displacements shift to\nthe right. In any direction, vacant bits are filled with zeros. In\nparticular, displacements with absolute values higher than 31 result in\nzero (all bits are shifted out).\n\nFor positive displacements, the following equality holds:\n\n         assert(bit32.lshift(b, disp) == (b * 2^disp) % 2^32)",
      "signature": "bit32.lshift (x, disp)"
    },
    "rrotate": {
      "description": "# bit32.rrotate (x, disp)\nReturns the number `x` rotated `disp` bits to the right. The number\n`disp` may be any representable integer.\n\nFor any valid displacement, the following identity holds:\n\n         assert(bit32.rrotate(x, disp) == bit32.rrotate(x, disp % 32))\n\nIn particular, negative displacements rotate to the left.",
      "signature": "bit32.rrotate (x, disp)"
    },
    "rshift": {
      "description": "# bit32.rshift (x, disp)\nReturns the number `x` shifted `disp` bits to the right. The number\n`disp` may be any representable integer. Negative displacements shift to\nthe left. In any direction, vacant bits are filled with zeros. In\nparticular, displacements with absolute values higher than 31 result in\nzero (all bits are shifted out).\n\nFor positive displacements, the following equality holds:\n\n         assert(bit32.rshift(b, disp) == math.floor(b % 2^32 / 2^disp))\n\nThis shift operation is what is called logical shift.\n\n6.8 – Input and Output Facilities\n---------------------------------\n\nThe I/O library provides two different styles for file manipulation. The\nfirst one uses implicit file descriptors; that is, there are operations\nto set a default input file and a default output file, and all\ninput/output operations are over these default files. The second style\nuses explicit file descriptors.\n\nWhen using implicit file descriptors, all operations are supplied by\ntable `io`. When using explicit file descriptors, the operation\n{`io.open`}(#pdf-io.open) returns a file descriptor and then all\noperations are supplied as methods of the file descriptor.\n\nThe table `io` also provides three predefined file descriptors with\ntheir usual meanings from C: `io.stdin`, `io.stdout`, and `io.stderr`.\nThe I/O library never closes these files.\n\nUnless otherwise stated, all I/O functions return **nil** on failure\n(plus an error message as a second result and a system-dependent error\ncode as a third result) and some value different from **nil** on\nsuccess. On non-Posix systems, the computation of the error message and\nerror code in case of errors may be not thread safe, because they rely\non the global C variable `errno`.",
      "signature": "bit32.rshift (x, disp)"
    }
  },
  "io": {
    "close": {
      "description": "# io.close ({file})\nEquivalent to `file:close()`. Without a `file`, closes the default\noutput file.",
      "signature": "io.close ({file})"
    },
    "flush": {
      "description": "# io.flush ()\nEquivalent to `io.output():flush()`.",
      "signature": "io.flush ()"
    },
    "input": {
      "description": "# io.input ({file})\nWhen called with a file name, it opens the named file (in text mode),\nand sets its handle as the default input file. When called with a file\nhandle, it simply sets this file handle as the default input file. When\ncalled without parameters, it returns the current default input file.\n\nIn case of errors this function raises the error, instead of returning\nan error code.",
      "signature": "io.input ({file})"
    },
    "lines": {
      "description": "# io.lines ({filename ···})\nOpens the given file name in read mode and returns an iterator function\nthat works like `file:lines(···)` over the opened file. When the\niterator function detects the end of file, it returns **nil** (to finish\nthe loop) and automatically closes the file.\n\nThe call `io.lines()` (with no file name) is equivalent to\n`io.input():lines()`; that is, it iterates over the lines of the default\ninput file. In this case it does not close the file when the loop ends.\n\nIn case of errors this function raises the error, instead of returning\nan error code.",
      "signature": "io.lines ({filename ···})"
    },
    "open": {
      "description": "# io.open (filename {, mode})\nThis function opens a file, in the mode specified in the string `mode`.\nIt returns a new file handle, or, in case of errors, **nil** plus an\nerror message.\n\nThe `mode` string can be any of the following:\n\n-   **\"`r`\":** read mode (the default);\n-   **\"`w`\":** write mode;\n-   **\"`a`\":** append mode;\n-   **\"`r+`\":** update mode, all previous data is preserved;\n-   **\"`w+`\":** update mode, all previous data is erased;\n-   **\"`a+`\":** append update mode, previous data is preserved, writing\n    is only allowed at the end of file.\n\nThe `mode` string can also have a '`b`' at the end, which is needed in\nsome systems to open the file in binary mode.",
      "signature": "io.open (filename {, mode})"
    },
    "output": {
      "description": "# io.output ({file})\nSimilar to {`io.input`}(#pdf-io.input), but operates over the default\noutput file.",
      "signature": "io.output ({file})"
    },
    "popen": {
      "description": "# io.popen (prog {, mode})\nThis function is system dependent and is not available on all platforms.\n\nStarts program `prog` in a separated process and returns a file handle\nthat you can use to read data from this program (if `mode` is `\"r\"`, the\ndefault) or to write data to this program (if `mode` is `\"w\"`).",
      "signature": "io.popen (prog {, mode})"
    },
    "read": {
      "description": "# io.read (···)\nEquivalent to `io.input():read(···)`.",
      "signature": "io.read (···)"
    },
    "tmpfile": {
      "description": "# io.tmpfile ()\nReturns a handle for a temporary file. This file is opened in update\nmode and it is automatically removed when the program ends.",
      "signature": "io.tmpfile ()"
    },
    "type": {
      "description": "# io.type (obj)\nChecks whether `obj` is a valid file handle. Returns the string `\"file\"`\nif `obj` is an open file handle, `\"closed file\"` if `obj` is a closed\nfile handle, or **nil** if `obj` is not a file handle.",
      "signature": "io.type (obj)"
    },
    "write": {
      "description": "# io.write (···)\nEquivalent to `io.output():write(···)`.",
      "signature": "io.write (···)"
    }
  },
  "file": {
    "close": {
      "description": "# file:close ()\nCloses `file`. Note that files are automatically closed when their\nhandles are garbage collected, but that takes an unpredictable amount of\ntime to happen.\n\nWhen closing a file handle created with {`io.popen`}(#pdf-io.popen),\n{`file:close`}(#pdf-file:close) returns the same values returned by\n{`os.execute`}(#pdf-os.execute).",
      "signature": "file:close ()"
    },
    "flush": {
      "description": "# file:flush ()\nSaves any written data to `file`.",
      "signature": "file:flush ()"
    },
    "lines": {
      "description": "# file:lines (···)\nReturns an iterator function that, each time it is called, reads the\nfile according to the given formats. When no format is given, uses \"\\*l\"\nas a default. As an example, the construction\n\n         for c in file:lines(1) do body end\n\nwill iterate over all characters of the file, starting at the current\nposition. Unlike {`io.lines`}(#pdf-io.lines), this function does not\nclose the file when the loop ends.\n\nIn case of errors this function raises the error, instead of returning\nan error code.",
      "signature": "file:lines (···)"
    },
    "read": {
      "description": "# file:read (···)\nReads the file `file`, according to the given formats, which specify\nwhat to read. For each format, the function returns a string (or a\nnumber) with the characters read, or **nil** if it cannot read data with\nthe specified format. When called without formats, it uses a default\nformat that reads the next line (see below).\n\nThe available formats are\n\n-   **\"`*n`\":** reads a number; this is the only format that returns a\n    number instead of a string.\n-   **\"`*a`\":** reads the whole file, starting at the current position.\n    On end of file, it returns the empty string.\n-   **\"`*l`\":** reads the next line skipping the end of line, returning\n    **nil** on end of file. This is the default format.\n-   **\"`*L`\":** reads the next line keeping the end of line (if\n    present), returning **nil** on end of file.\n-   ***number*:** reads a string with up to this number of bytes,\n    returning **nil** on end of file. If number is zero, it reads\n    nothing and returns an empty string, or **nil** on end of file.",
      "signature": "file:read (···)"
    },
    "seek": {
      "description": "# file:seek ({whence {, offset}})\nSets and gets the file position, measured from the beginning of the\nfile, to the position given by `offset` plus a base specified by the\nstring `whence`, as follows:\n\n-   **\"`set`\":** base is position 0 (beginning of the file);\n-   **\"`cur`\":** base is current position;\n-   **\"`end`\":** base is end of file;\n\nIn case of success, `seek` returns the final file position, measured in\nbytes from the beginning of the file. If `seek` fails, it returns\n**nil**, plus a string describing the error.\n\nThe default value for `whence` is `\"cur\"`, and for `offset` is 0.\nTherefore, the call `file:seek()` returns the current file position,\nwithout changing it; the call `file:seek(\"set\")` sets the position to\nthe beginning of the file (and returns 0); and the call\n`file:seek(\"end\")` sets the position to the end of the file, and returns\nits size.",
      "signature": "file:seek ({whence {, offset}})"
    },
    "setvbuf": {
      "description": "# file:setvbuf (mode {, size})\nSets the buffering mode for an output file. There are three available\nmodes:\n\n-   **\"`no`\":** no buffering; the result of any output operation appears\n    immediately.\n-   **\"`full`\":** full buffering; output operation is performed only\n    when the buffer is full or when you explicitly `flush` the file (see\n    {`io.flush`}(#pdf-io.flush)).\n-   **\"`line`\":** line buffering; output is buffered until a newline is\n    output or there is any input from some special files (such as a\n    terminal device).\n\nFor the last two cases, `size` specifies the size of the buffer, in\nbytes. The default is an appropriate size.",
      "signature": "file:setvbuf (mode {, size})"
    },
    "write": {
      "description": "# file:write (···)\nWrites the value of each of its arguments to `file`. The arguments must\nbe strings or numbers.\n\nIn case of success, this function returns `file`. Otherwise it returns\n**nil** plus a string describing the error.\n\n6.9 – Operating System Facilities\n---------------------------------\n\nThis library is implemented through table `os`.",
      "signature": "file:write (···)"
    }
  },
  "os": {
    "clock": {
      "description": "# os.clock ()\nReturns an approximation of the amount in seconds of CPU time used by\nthe program.",
      "signature": "os.clock ()"
    },
    "date": {
      "description": "# os.date ({format {, time}})\nReturns a string or a table containing date and time, formatted\naccording to the given string `format`.\n\nIf the `time` argument is present, this is the time to be formatted (see\nthe {`os.time`}(#pdf-os.time) function for a description of this value).\nOtherwise, `date` formats the current time.\n\nIf `format` starts with '`!`', then the date is formatted in Coordinated\nUniversal Time. After this optional character, if `format` is the string\n\"`*t`\", then `date` returns a table with the following fields: `year`\n(four digits), `month` (1–12), `day` (1–31), `hour` (0–23), `min`\n(0–59), `sec` (0–61), `wday` (weekday, Sunday is 1), `yday` (day of the\nyear), and `isdst` (daylight saving flag, a boolean). This last field\nmay be absent if the information is not available.\n\nIf `format` is not \"`*t`\", then `date` returns the date as a string,\nformatted according to the same rules as the ANSI C function `strftime`.\n\nWhen called without arguments, `date` returns a reasonable date and time\nrepresentation that depends on the host system and on the current locale\n(that is, `os.date()` is equivalent to `os.date(\"%c\")`).\n\nOn non-Posix systems, this function may be not thread safe because of\nits reliance on C function `gmtime` and C function `localtime`.",
      "signature": "os.date ({format {, time}})"
    },
    "difftime": {
      "description": "# os.difftime (t2, t1)\nReturns the number of seconds from time `t1` to time `t2`. In POSIX,\nWindows, and some other systems, this value is exactly `t2`*-*`t1`.",
      "signature": "os.difftime (t2, t1)"
    },
    "execute": {
      "description": "# os.execute ({command})\nThis function is equivalent to the ANSI C function `system`. It passes\n`command` to be executed by an operating system shell. Its first result\nis **true** if the command terminated successfully, or **nil**\notherwise. After this first result the function returns a string and a\nnumber, as follows:\n\n-   **\"`exit`\":** the command terminated normally; the following number\n    is the exit status of the command.\n-   **\"`signal`\":** the command was terminated by a signal; the\n    following number is the signal that terminated the command.\n\nWhen called without a `command`, `os.execute` returns a boolean that is\ntrue if a shell is available.",
      "signature": "os.execute ({command})"
    },
    "exit": {
      "description": "# os.exit ({code {, close})\nCalls the ANSI C function `exit` to terminate the host program. If\n`code` is **true**, the returned status is `EXIT_SUCCESS`; if `code` is\n**false**, the returned status is `EXIT_FAILURE`; if `code` is a number,\nthe returned status is this number. The default value for `code` is\n**true**.\n\nIf the optional second argument `close` is true, closes the Lua state\nbefore exiting.",
      "signature": "os.exit ({code {, close})"
    },
    "getenv": {
      "description": "# os.getenv (varname)\nReturns the value of the process environment variable `varname`, or\n**nil** if the variable is not defined.",
      "signature": "os.getenv (varname)"
    },
    "remove": {
      "description": "# os.remove (filename)\nDeletes the file (or empty directory, on POSIX systems) with the given\nname. If this function fails, it returns **nil**, plus a string\ndescribing the error and the error code.",
      "signature": "os.remove (filename)"
    },
    "rename": {
      "description": "# os.rename (oldname, newname)\nRenames file or directory named `oldname` to `newname`. If this function\nfails, it returns **nil**, plus a string describing the error and the\nerror code.",
      "signature": "os.rename (oldname, newname)"
    },
    "setlocale": {
      "description": "# os.setlocale (locale {, category})\nSets the current locale of the program. `locale` is a system-dependent\nstring specifying a locale; `category` is an optional string describing\nwhich category to change: `\"all\"`, `\"collate\"`, `\"ctype\"`, `\"monetary\"`,\n`\"numeric\"`, or `\"time\"`; the default category is `\"all\"`. The function\nreturns the name of the new locale, or **nil** if the request cannot be\nhonored.\n\nIf `locale` is the empty string, the current locale is set to an\nimplementation-defined native locale. If `locale` is the string \"`C`\",\nthe current locale is set to the standard C locale.\n\nWhen called with **nil** as the first argument, this function only\nreturns the name of the current locale for the given category.\n\nThis function may be not thread safe because of its reliance on\nC function `setlocale`.",
      "signature": "os.setlocale (locale {, category})"
    },
    "time": {
      "description": "# os.time ({table})\nReturns the current time when called without arguments, or a time\nrepresenting the date and time specified by the given table. This table\nmust have fields `year`, `month`, and `day`, and may have fields `hour`\n(default is 12), `min` (default is 0), `sec` (default is 0), and `isdst`\n(default is **nil**). For a description of these fields, see the\n{`os.date`}(#pdf-os.date) function.\n\nThe returned value is a number, whose meaning depends on your system. In\nPOSIX, Windows, and some other systems, this number counts the number of\nseconds since some given start time (the \"epoch\"). In other systems, the\nmeaning is not specified, and the number returned by `time` can be used\nonly as an argument to {`os.date`}(#pdf-os.date) and\n{`os.difftime`}(#pdf-os.difftime).",
      "signature": "os.time ({table})"
    },
    "tmpname": {
      "description": "# os.tmpname ()\nReturns a string with a file name that can be used for a temporary file.\nThe file must be explicitly opened before its use and explicitly removed\nwhen no longer needed.\n\nOn POSIX systems, this function also creates a file with that name, to\navoid security risks. (Someone else might create the file with wrong\npermissions in the time between getting the name and creating the file.)\nYou still have to open the file to use it and to remove it (even if you\ndo not use it).\n\nWhen possible, you may prefer to use {`io.tmpfile`}(#pdf-io.tmpfile),\nwhich automatically removes the file when the program ends.\n\n6.10 – The Debug Library\n------------------------\n\nThis library provides the functionality of the debug interface\n({§4.9}(#4.9)) to Lua programs. You should exert care when using this\nlibrary. Several of its functions violate basic assumptions about Lua\ncode (e.g., that variables local to a function cannot be accessed from\noutside; that userdata metatables cannot be changed by Lua code; that\nLua programs do not crash) and therefore can compromise otherwise secure\ncode. Moreover, some functions in this library may be slow.\n\nAll functions in this library are provided inside the `debug` table. All\nfunctions that operate over a thread have an optional first argument\nwhich is the thread to operate over. The default is always the current\nthread.",
      "signature": "os.tmpname ()"
    }
  },
  "debug": {
    "debug": {
      "description": "# debug.debug ()\nEnters an interactive mode with the user, running each string that the\nuser enters. Using simple commands and other debug facilities, the user\ncan inspect global and local variables, change their values, evaluate\nexpressions, and so on. A line containing only the word `cont` finishes\nthis function, so that the caller continues its execution.\n\nNote that commands for `debug.debug` are not lexically nested within any\nfunction and so have no direct access to local variables.",
      "signature": "debug.debug ()"
    },
    "gethook": {
      "description": "# debug.gethook ({thread})\nReturns the current hook settings of the thread, as three values: the\ncurrent hook function, the current hook mask, and the current hook count\n(as set by the {`debug.sethook`}(#pdf-debug.sethook) function).",
      "signature": "debug.gethook ({thread})"
    },
    "getinfo": {
      "description": "# debug.getinfo ({thread,} f {, what})\nReturns a table with information about a function. You can give the\nfunction directly or you can give a number as the value of `f`, which\nmeans the function running at level `f` of the call stack of the given\nthread: level 0 is the current function (`getinfo` itself); level 1 is\nthe function that called `getinfo` (except for tail calls, which do not\ncount on the stack); and so on. If `f` is a number larger than the\nnumber of active functions, then `getinfo` returns **nil**.\n\nThe returned table can contain all the fields returned by\n{`lua_getinfo`}(#lua_getinfo), with the string `what` describing which\nfields to fill in. The default for `what` is to get all information\navailable, except the table of valid lines. If present, the option '`f`'\nadds a field named `func` with the function itself. If present, the\noption '`L`' adds a field named `activelines` with the table of valid\nlines.\n\nFor instance, the expression `debug.getinfo(1,\"n\").name` returns a table\nwith a name for the current function, if a reasonable name can be found,\nand the expression `debug.getinfo(print)` returns a table with all\navailable information about the {`print`}(#pdf-print) function.",
      "signature": "debug.getinfo ({thread,} f {, what})"
    },
    "getlocal": {
      "description": "# debug.getlocal ({thread,} f, local)\nThis function returns the name and the value of the local variable with\nindex `local` of the function at level `f` of the stack. This function\naccesses not only explicit local variables, but also parameters,\ntemporaries, etc.\n\nThe first parameter or local variable has index 1, and so on, until the\nlast active variable. Negative indices refer to vararg parameters; -1 is\nthe first vararg parameter. The function returns **nil** if there is no\nvariable with the given index, and raises an error when called with a\nlevel out of range. (You can call {`debug.getinfo`}(#pdf-debug.getinfo)\nto check whether the level is valid.)\n\nVariable names starting with '`(`' (open parenthesis) represent internal\nvariables (loop control variables, temporaries, varargs, and C function\nlocals).\n\nThe parameter `f` may also be a function. In that case, `getlocal`\nreturns only the name of function parameters.",
      "signature": "debug.getlocal ({thread,} f, local)"
    },
    "getmetatable": {
      "description": "# debug.getmetatable (value)\nReturns the metatable of the given `value` or **nil** if it does not\nhave a metatable.",
      "signature": "debug.getmetatable (value)"
    },
    "getregistry": {
      "description": "# debug.getregistry ()\nReturns the registry table (see {§4.5}(#4.5)).",
      "signature": "debug.getregistry ()"
    },
    "getupvalue": {
      "description": "# debug.getupvalue (f, up)\nThis function returns the name and the value of the upvalue with index\n`up` of the function `f`. The function returns **nil** if there is no\nupvalue with the given index.",
      "signature": "debug.getupvalue (f, up)"
    },
    "getuservalue": {
      "description": "# debug.getuservalue (u)\nReturns the Lua value associated to `u`. If `u` is not a userdata,\nreturns **nil**.",
      "signature": "debug.getuservalue (u)"
    },
    "sethook": {
      "description": "# debug.sethook ({thread,} hook, mask {, count})\nSets the given function as a hook. The string `mask` and the number\n`count` describe when the hook will be called. The string mask may have\nthe following characters, with the given meaning:\n\n-   **'`c`':** the hook is called every time Lua calls a function;\n-   **'`r`':** the hook is called every time Lua returns from a\n    function;\n-   **'`l`':** the hook is called every time Lua enters a new line of\n    code.\n\nWith a `count` different from zero, the hook is called after every\n`count` instructions.\n\nWhen called without arguments, {`debug.sethook`}(#pdf-debug.sethook)\nturns off the hook.\n\nWhen the hook is called, its first parameter is a string describing the\nevent that has triggered its call: `\"call\"` (or `\"tail call\"`),\n`\"return\"`, `\"line\"`, and `\"count\"`. For line events, the hook also gets\nthe new line number as its second parameter. Inside a hook, you can call\n`getinfo` with level 2 to get more information about the running\nfunction (level 0 is the `getinfo` function, and level 1 is the hook\nfunction).",
      "signature": "debug.sethook ({thread,} hook, mask {, count})"
    },
    "setlocal": {
      "description": "# debug.setlocal ({thread,} level, local, value)\nThis function assigns the value `value` to the local variable with index\n`local` of the function at level `level` of the stack. The function\nreturns **nil** if there is no local variable with the given index, and\nraises an error when called with a `level` out of range. (You can call\n`getinfo` to check whether the level is valid.) Otherwise, it returns\nthe name of the local variable.\n\nSee {`debug.getlocal`}(#pdf-debug.getlocal) for more information about\nvariable indices and names.",
      "signature": "debug.setlocal ({thread,} level, local, value)"
    },
    "setmetatable": {
      "description": "# debug.setmetatable (value, table)\nSets the metatable for the given `value` to the given `table` (which can\nbe **nil**). Returns `value`.",
      "signature": "debug.setmetatable (value, table)"
    },
    "setupvalue": {
      "description": "# debug.setupvalue (f, up, value)\nThis function assigns the value `value` to the upvalue with index `up`\nof the function `f`. The function returns **nil** if there is no upvalue\nwith the given index. Otherwise, it returns the name of the upvalue.",
      "signature": "debug.setupvalue (f, up, value)"
    },
    "setuservalue": {
      "description": "# debug.setuservalue (udata, value)\nSets the given `value` as the Lua value associated to the given `udata`.\n`value` must be a table or **nil**; `udata` must be a full userdata.\n\nReturns `udata`.",
      "signature": "debug.setuservalue (udata, value)"
    },
    "traceback": {
      "description": "# debug.traceback ({thread,} {message {, level}})\nIf `message` is present but is neither a string nor **nil**, this\nfunction returns `message` without further processing. Otherwise, it\nreturns a string with a traceback of the call stack. An optional\n`message` string is appended at the beginning of the traceback. An\noptional `level` number tells at which level to start the traceback\n(default is 1, the function calling `traceback`).",
      "signature": "debug.traceback ({thread,} {message {, level}})"
    },
    "upvalueid": {
      "description": "# debug.upvalueid (f, n)\nReturns an unique identifier (as a light userdata) for the upvalue\nnumbered `n` from the given function.\n\nThese unique identifiers allow a program to check whether different\nclosures share upvalues. Lua closures that share an upvalue (that is,\nthat access a same external local variable) will return identical ids\nfor those upvalue indices.",
      "signature": "debug.upvalueid (f, n)"
    },
    "upvaluejoin": {
      "description": "# debug.upvaluejoin (f1, n1, f2, n2)\nMake the `n1`-th upvalue of the Lua closure `f1` refer to the `n2`-th\nupvalue of the Lua closure `f2`.",
      "signature": "debug.upvaluejoin (f1, n1, f2, n2)"
    }
  }
}

