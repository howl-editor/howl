-- Copyright 2017 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

{
  lexer: bundle_load('cython_lexer')
  structure: (editor) =>
    [l for l in *editor.buffer.lines when l\match('^%s*class%s') or l\match('^%s*def%s') or l\match("^%s*cdef%s") or l\match("^%s*cpdef%s")]
}
