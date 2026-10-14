-- Copyright 2026 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

howl.util.lpeg_lexer ->
  c = capture

  ident = (alpha + '_')^1 * (alpha + digit + '_')^0

  -- a word right after one of these is a field or method name, whatever it is
  after_access = B(S'.:@')

  -- a word that's the start of another comes after it, as with elseif and else
  keyword = c 'keyword', -after_access * word {
    'and', 'break', 'class', 'continue', 'do', 'elseif', 'else', 'export', 'extends',
    'for', 'from', 'if', 'import', 'in', 'local', 'not', 'or', 'return', 'super',
    'switch', 'then', 'unless', 'when', 'while', 'with'
  }

  -- Lua keywords that Howlscript doesn't use can't be variable names, but they can
  -- be fields and keys
  lua_keyword = c 'error', -after_access * word { 'end', 'function', 'goto', 'repeat', 'until' }

  -- '--' touching a name or ']' decrements, anywhere else it starts a comment
  decrement = c 'operator', B(alnum + S'_]') * '--'
  comment = c 'comment', P'--' * scan_until(eol)

  hexadecimal_number =  P'0' * S'xX' * xdigit^1 * (P'.' * xdigit^1)^0 * (S'pP' * S'-+'^0 * xdigit^1)^0
  float = digit^0 * P'.' * digit^1
  number = c 'number', any({
    hexadecimal_number * any('LL', 'll', 'ULL', 'ull')^-1,
    digit^1 * any('LL', 'll', 'ULL', 'ull'),
    (float + digit^1) * (S'eE' * P('-')^0 * digit^1)^0
  })

  operator = c 'operator', any {
    any { '->', '=>', '!=', '~=', 'or=', 'and=' },
    S'+-*/%^#=<>:,.(){}[]'
  }

  -- MoonScript's \ and ! calls and Lua's semicolons aren't Howlscript
  illegal = c 'error', S'\\!;'

  identifier = c 'identifier', ident
  member = c 'member', (P'@@' + '@' + 'self.') * ident^0
  special = c 'special', -after_access * word { 'true', 'false', 'nil' }
  type_name = c 'type', upper^1 * (alpha + digit + '_')^0
  type_def = sequence {
    c('keyword', 'class'),
    c('whitespace', blank^1),
    c('type_def', upper^1 * (alpha + digit + '_')^0)
  }

  sq_string = span("'", "'", '\\')
  dq_string = span('"', '"', P'\\')
  long_string_start = P'[' * Cg(P('=')^0, 'lvl') * '['
  long_string_end = ']' * match_back('lvl') * ']'
  long_string = long_string_start * scan_to(long_string_end)^-1

  -- a key needs a space after its colon, as `a:b` calls a method. The short form
  -- `:name` can't follow a value, and isn't followed by a call, which makes it a
  -- method call in a with block.
  key_end = P':' * #(blank + eol + P(-1))
  key = c 'key', any {
    -B(alnum + S'_)]"\'') * P':' * ident * -P'(',
    ident * key_end,
    (sq_string + dq_string) * key_end
  }

  ws = c 'whitespace', blank^0

  cdef = sequence {
    c('identifier', 'ffi'),
    c('operator', '.'),
    c('identifier', 'cdef'),
    c('operator', '(')^-1,
    ws,
    any {
      sequence {
        c('string', '[['),
        sub_lex('c', ']]'),
        c('string', ']]')^-1,
      },
      sequence {
        c('string', '"'),
        sub_lex('c', '"'),
        c('string', '"')^-1,
      },
      sequence {
        c('string', "'"),
        sub_lex('c', "'"),
        c('string', "'")^-1,
      }
    }
  }

  P {
    'all'
    all: any {
      number, key, V'string', decrement, comment, operator, illegal, special, type_def,
      keyword, member, type_name, lua_keyword, V'fdecl', cdef, identifier
    }
    string: any {
      c 'string', any { sq_string, long_string }
      V'dq_string'
    }
    interpolation: #P'#' * (-P'}' * (V'all' + 1))^1 * c('operator', '}') * V'dq_string_chunk'
    dq_string_chunk: c('string', scan_to(P'"' + #P'#{', P'\\')) * V('interpolation')^0
    dq_string: c('string', '"') * (V'dq_string_chunk')
    fdecl: sequence {
      c('fdecl', ident),
      ws,
      c('operator', '='),
      ws,
      sequence({
        c('operator', '('),
        any({
          key,
          -#P')' * operator,
          special,
          member,
          identifier,
          c('whitespace', blank^1),
          number,
          V'string'
        })^0,
        c('operator', ')'),
        ws,
      })^0,
      c('operator', any('->', '=>')),
    }
  }
