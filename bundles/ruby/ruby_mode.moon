-- Copyright 2013 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

continuation_pattern = r'(?:[,+=]|\\|\\||&&)\\s*$'

is_continued = (line) -> line\umatch continuation_pattern

mode = {
  lexer: bundle_load('ruby_lexer')

  comment_syntax: '#'

  default_config:
    word_pattern: '%w[%w%d_]+[?!=]?'

  indent_after_patterns: {
    {r'^\\s*(def|class|if|elsif|else|unless|module|begin|rescue|ensure|when|case|while)\\b', '%send%s*$'},
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

  indent_for: (line, indent_level) =>
    prev = line.previous_non_blank
    if prev
      preceding = prev.previous_non_blank
      if is_continued prev
        return prev.indentation if preceding and is_continued(preceding)
        return prev.indentation + indent_level
      elseif preceding and is_continued preceding
        return prev.indentation - (indent_level * 2)

    return @parent.indent_for self, line, indent_level
}

-> mode
