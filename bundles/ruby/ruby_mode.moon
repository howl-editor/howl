-- Copyright 2013-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

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
      if is_hash_entry(prev) or preceding and (is_continued(preceding) or preceding.indentation < prev.indentation)
        return prev.indentation
      return prev.indentation + indent_level
    elseif preceding and is_continued preceding
      start = continuation_start(preceding)
      if is_hash_entry start
        preceding = start.previous_non_blank
        return preceding.indentation if preceding

      return start.indentation

{
  lexer: bundle_load('ruby_lexer')

  comment_syntax: '#'
  word_pattern: r'\\b\\w[\\w\\d_]+[?!=]?\\b'

  default_config:
    inspectors_on_idle: { 'ruby' }

  indentation: {
    more_after: {
      {r'^\\s*(def|class|if|elsif|else|unless|module|begin|rescue|ensure|when|case|while)\\b', '%send%s*$'},
      {r'=\\s+(?:if|begin)\\b', '%send%s*$'},
      r'(\\bdo|{)\\s*(?:\\|[^|]*\\|)?\\s*$',
      '[[{(]%s*$'
    }

    less_for: {
      r'^\\s*(elsif|else|end|rescue|ensure|when)',
      r'^\\s*[]}\\)]'
    }
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
      { r'\\bdo(?:\\s*\\|[^|]+\\|)?\\s*$', '^%s*end', 'end' },
      { r'^\\s*def\\s+\\w[\\w.\\d?!]+(?:\\s*\\([^)]*\\))?\\s*$', '^%s*end', 'end' },
      { r'^\\s*(class|module)\\s+\\p{Lu}[\\w\\d]*(\\s*<\\s*\\p{Lu}[\\w\\d]*)?\\s*$', '^%s*end', 'end' },
      { r'^\\s*(if|unless|case)\\s+', '^%s*end', 'end' },
      { '{%s*$', '^%s*}', '}'},
      { '%[%s*$', '^%s*%]', ']'},
      { '%(%s*$', '^%s*%)', ')'},
    }

  indent_for: (line, indent_level) =>
    cont_indent = continuation_indent line, indent_level
    if cont_indent
      if @patterns_match line, @indentation.less_for
        cont_indent -= indent_level
      return math.max 0, cont_indent

    super line, indent_level
}
