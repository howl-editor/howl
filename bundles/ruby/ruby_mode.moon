-- Copyright 2013 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

import formatting from howl

continuation_pattern = r'(?:[,+=]|\\|\\||&&)\\s*$'
hash_entry_pattern = r'^\\s*(?:\\S+:|[\'"][^\'"]+[\'"]\\s*=>)'

is_hash_entry = (line) -> line\umatch hash_entry_pattern
is_continued = (line) -> line\umatch continuation_pattern

continuation_start = (line) ->
  prev = line.previous_non_blank

  while prev and is_continued prev
    line = prev
    prev = line.previous_non_blank

  line

continuation_indent = (line, indent_level) ->
  prev = line.previous_non_blank
  if prev
    preceding = prev.previous_non_blank
    if is_continued prev
      if is_hash_entry(prev) or preceding and is_continued(preceding)
        return prev.indentation
      return prev.indentation + indent_level
    elseif preceding and is_continued preceding
      start = continuation_start(preceding)
      if is_hash_entry start
        preceding = start.previous_non_blank
        return preceding.indentation if preceding

      return start.indentation

mode = {
  lexer: bundle_load('ruby_lexer')

  comment_syntax: '#'

  default_config:
    word_pattern: '%w[%w%d_]+[?!=]?'

  indent_after_patterns: {
    {r'^\\s*(def|class|if|elsif|else|unless|module|begin|rescue|ensure|when|case|while)\\b', '%send%s*$'},
    {r'=\\s+(?:if|begin)\\b', '%send%s*$'},
    r'\\s(do|{)\\s*(?:\\|[^|]*\\|)?\\s*$',
    '[[{(]%s*$'
  }

  dedent_patterns: {
    r'^\\s*(elsif|else|end|rescue|ensure|when)',
    r'^\\s*[]}\\)]'
  }

  auto_pairs: {
    '(': ')'
    '[': ']'
    '{': '}'
    "'": "'"
    '"': '"'
    '|': '|'
  }

  code_blocks:
    multiline: {
      { r'\\s+do(?:\\s*\\|[^|]+\\|)?\\s*$', '^%s*end', 'end' },
      { r'^\\s*def\\s+\\w[\\w\\d]+(?:\\s*\\([^)]*\\))?\\s*$', '^%s*end', 'end' },
      { r'^\\s*(class|module)\\s+\\p{Lu}[\\w\\d]*\\s*$', '^%s*end', 'end' },
      { '{%s*$', '^%s*}', '}'}
      { '%[%s*$', '^%s*%]', ']'}
      { '%(%s*$', '^%s*%)', ')'}
    }

  indent_for: (line, indent_level) =>
    cont_indent = continuation_indent line, indent_level
    if cont_indent
      if @patterns_match line, @dedent_patterns
        cont_indent -= indent_level
      return math.max 0, cont_indent

    return @parent.indent_for self, line, indent_level
}

-> mode
