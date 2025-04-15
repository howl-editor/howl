-- Copyright 2025 The Howl Developers
-- License: MIT (see LICENSE file)

-- This lexer recognizes Jinja2 tags and composes with a base lexer (e.g., HTML).

(base) ->
  howl.util.lpeg_lexer ->
    c = capture

    ws_p = blank^1
    letter_or_underscore = alpha + P'_'
    alnum_or_underscore = alnum + P'_'
    ident_p = letter_or_underscore * alnum_or_underscore^0

    num_p = any { float, hexadecimal, octal, digit^1 }

    esc_char = P'\\' * P(1)
    sgl_str_content = (P(1) - S"\'") + esc_char
    dbl_str_content = (P(1) - S'\"') + esc_char
    sgl_str_p = sequence { P"'", sgl_str_content^0, P"'" }
    dbl_str_p = sequence { P'"', dbl_str_content^0, P'"' }
    str_p = sgl_str_p + dbl_str_p

    op_p = any {
      '**', '//', '==', '!=', '<=', '>=', '=>', '+', '-', '*',
      '/', '%', '<', '>', '&', '|', '(', ')', '[', ']', '.',
      ',', ':', '=', '~'
    }

    keyword_operators = c('operator', word { 'and', 'or', 'not', 'in', 'is' })
    keyword_literals = c('literal', word { 'True', 'False', 'None' })
    keyword_keywords = c('keyword', word { 'if', 'else', 'elif', 'endif', 'for', 'endfor' })

    variable_capture = c('variable', ident_p)

    jinja_internal = any {
      c('whitespace', ws_p),
      c('string', str_p),
      c('number', num_p),
      keyword_operators,
      keyword_literals,
      keyword_keywords,
      variable_capture,
      c('operator', op_p)
    }

    jinja_expression_rule = sequence {
      c('operator', P'{{'),
      sub_lex_by_inline('embedded', scan_until('}}'), jinja_internal),
      c('operator', P'}}')
    }

    jinja_statement_rule = sequence {
      c('operator', P'{%'),
      -- Lex content up to '%}' using jinja_internal rules
      sub_lex_by_inline('embedded', scan_until('%}'), jinja_internal),
      c('operator', P'%}')
    }

    jinja_comment_rule = c('comment', sequence {
      P'{#',
      scan_to '#}', -- scan_to is simpler for comments
      P'#}'
    })

    jinja_overlay_pattern = any {
      jinja_expression_rule,
      jinja_statement_rule,
      jinja_comment_rule
    }

    compose base, jinja_overlay_pattern
