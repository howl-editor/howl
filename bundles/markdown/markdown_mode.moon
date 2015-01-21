-- Copyright 2013 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

is_header = (line) ->
  return true if line\match('^%#+%s')
  next = line.next
  return next and next\match('^[-=]+%s*$')

{
  lexer: bundle_load('markdown_lexer')

  default_config:
    word_pattern: r'\\b\\w[\\w\\d_-]+\\b'
    cursor_line_highlighted: false

  auto_pairs: {
      '(': ')'
      '[': ']'
      '{': '}'
      '"': '"'
    }

  code_blocks:
    multiline: {
      { r'```(\\w+)?\\s*$', '^```', '```'}
    }

  is_paragraph_break: (line) ->
    return true if line.is_blank or is_header line
    prev = line.previous
    return true if prev and (is_header(prev) or prev\match('^```'))
    line\umatch r'^(?:[\\s-*[]|```)'

  structure: (editor) =>
    [l for l in *editor.buffer.lines when is_header(l)]
}
