-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

print = print

(base) ->
  howl.util.lpeg_lexer ->
    expansion_start = P'<%' * S'=-'^-1
    expansion_end = P'-'^-1 * '%>'

    lua = P {
      any(V'expansion', V'string')
      -- any(V'expansion')

      expansion: sequence {
        capture('operator', expansion_start),
        sub_lex('lua', expansion_end),
        capture('operator', expansion_end)
      }

      string_chunk: sequence {
        capture('string', match_until(any(V'expansion', match_back('etlua_str_del')), 1)),
        sequence({
          V'expansion',
          V'string_chunk'
        })^-1
      }

      string: sequence {
        capture('string', Cg(S"'\"", 'etlua_str_del')),
        V'string_chunk',
        capture('string', match_back('etlua_str_del'))^-1
      }
    }

    -- print "base: #{}"
    compose base, lua
