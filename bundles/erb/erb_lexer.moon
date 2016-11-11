-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

(base) ->
  howl.util.lpeg_lexer ->

    ruby = P {
      any(V'expansion', V'string')

      expansion: sequence {
        capture('operator', P'<%' * P'='^-1),
        sub_lex('ruby', '%>'),
        capture('operator', '%>')
      }

      string_chunk: sequence {
        capture('string', match_until(any(V'expansion', match_back('erb_str_del')), 1)),
        sequence({
          V'expansion',
          V'string_chunk'
        })^-1
      }

      string: sequence {
        capture('string', Cg(S"'\"", 'erb_str_del')),
        V'string_chunk',
        capture('string', match_back('erb_str_del'))^-1
      }
    }

    compose base, ruby
