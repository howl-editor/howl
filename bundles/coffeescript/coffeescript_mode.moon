-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)
append = table.insert

find_previous_starter = (line) ->
  prev = line.previous_non_blank

  while prev and (prev.indentation > line.indentation or not prev\match '%a')
    prev = prev.previous_non_blank

  prev

class CoffeeScriptMode
  new: (lexer) =>
    @lexer = bundle_load lexer

  comment_syntax: '#'

  indentation: {
    more_after: {
      '[-=]>%s*$', -- fdecls
      '[([{:=]%s*$' -- hanging operators
      { r'^(.*=)?\\s*\\b(try|catch|finally|class|switch|for|when)\\b', '%sthen%s*' }, -- block starters
      { r'^\\s*\\b(if|unless|while|else\\s+if)\\b', '%sthen%s*'}, -- conditionals
      '^%s*else%s*$',
      { '=%s*if%s', '%sthen%s*' } -- 'if' used as rvalue
    }

    same_after: {
      ',%s*$',
    }

    less_for: {
      authoritive: false
      { '^%s*else%s+if%s', '%sthen%s*' },
      r'^\\s*(else|\\})\\s*$',
      '^%s*[]})]',
    }
  }

  auto_pairs: {
    '(': ')'
    '[': ']'
    '{': '}'
    '"': '"'
    "'": "'"
  }

  code_blocks:
    multiline: {
      { '{%s*$', '^%s*}', '}'}
      { '%[%s*$', '^%s*%]', ']'}
      { '%(%s*$', '^%s*%)', ')'}
      { '###%s*$', '^%s*###', '###'}
      { '///%s*$', '^%s*///', '///'}
      { '"""%s*$', '^%s*"""', '"""'}
      { "'''%s*$", "^%s*'''", "'''"}
    }

  indent_for: (line, indent_level) =>
    if line\match '^%s*%.'
      prev = find_previous_starter line
      return prev.indentation if prev and prev\match '^%s*%.'
      return prev.indentation + indent_level

    super line, indent_level

  structure: (editor) =>
    lines = {}
    parents = {}
    prev_line = nil

    patterns = {
      '%s*class%s+%w'
      r'\\w\\s*[=:]\\s*(\\([^)]*\\))?\\s*[=-]>'
      r'(?:it|describe|context)\\(?\\s+[\'"].+->\\s*$'
    }

    for line in *editor.buffer.lines
      if prev_line
        if prev_line.indentation < line.indentation
          append parents, prev_line
        else
          parents = [l for l in *parents when l.indentation < line.indentation]

      prev_line = line if line and not line.is_blank

      for p in *patterns
        if line\umatch p
          for _ = 1, #parents
            append lines, table.remove parents, 1

          append lines, line
          prev_line = nil
          break

    #lines > 0 and lines or self.parent.structure @, editor
