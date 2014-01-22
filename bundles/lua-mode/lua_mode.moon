import style from howl.ui

style.define 'longstring', 'string'

class LuaMode
  new: =>
    @lexer = howl.aux.ScintilluaLexer 'lua', bundle_file 'lua_lexer.lua'

  comment_syntax: '--'

  auto_pairs: {
    '(': ')'
    '[': ']'
    '{': '}'
    '"': '"'
    "'": "'"
  }

  indentation: {
    more_after: {
      '[({=]%s*(--.*|)$' -- hanging operators
      r'function\\b\\s*[^(]*\\([^)]*\\)\\s*(--.*|)$' -- function starter
      r'\\b(then|do)\\b\\s*(--.*|)$', -- block starters
      { '^%s*if%s+', '%s+end$' }
      r'^\\s*else\\b',
    }

    less_for: {
      r'^\\s*end\\b'
      '^%s*}'
      r'^\\s*else\\b'
      r'^\\s*elseif\\b'
      r'^\\s*\\}\\b'
    }
  }
