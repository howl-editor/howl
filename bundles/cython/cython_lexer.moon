-- Copyright 2017 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

howl.util.lpeg_lexer ->
  c = capture

  name = (alpha + '_')^1 * (alpha + digit + P'_')^0

  keyword = c 'keyword', word {
      'cimport', 'cdef', 'cpdef', 'ctypedef', 'struct', 'union', 'include', 'inline', 'public', 'extern'
  }

  typename = c 'type', word {
      'enum',
      'char', 'short', 'int', 'long', 'float', 'double', 'bint', 'unsigned'
      'object'
  }

  operator = c 'operator', S'[]*<>'

  cython_rules = P {
    any(V'cython_fdecl', keyword, typename)
    cython_fdecl: sequence {
      c('keyword', word {'cdef', 'cpdef'})
      sequence({
        c('whitespace', space^0)
        any(keyword, typename, operator)
      })^0
      c('whitespace', space^0)
      c('fdecl', name)
      c('whitespace', space^0)
      c('operator', '(')
    }
  }

  compose 'python', cython_rules
