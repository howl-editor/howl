-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

append = table.insert

class MoonscriptMode
  new: =>
    @lexer = bundle_load('moonscript_lexer')

    with howl.mode.by_name('lua')
      @api = .api
      @completers = .completers

  default_config:
    inspectors: { 'moonscript' }

  comment_syntax: '--'

  indentation: {
    more_after: {
      '[-=]>%s*$', -- fdecls
      '[([{:=]%s*$' -- hanging operators
      r'^\\s*\\b(class|switch|do|with|for|when)\\b', -- block starters
      { r'^\\s*\\b(elseif|if|while|unless)\\b', '%sthen%s*'}, -- conditionals
      '^%s*else%s*$',
      { '=%s*if%s', '%sthen%s*'} -- 'if' used as rvalue
    }

    same_after: {
      ',%s*$'
    }

    less_for: {
      authoritive: false
      r'^\\s*(else|\\})\\s*$',
      '^%s*[]})]',
      { '^%s*elseif%s', '%sthen%s*' }
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
      { '%[%[%s*$', '^%s*%]%]', ']]'}
    }

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
