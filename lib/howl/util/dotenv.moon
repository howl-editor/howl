-- Copyright 2026 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

-- Parses the variables of `.env` files, following python-dotenv's rules

ESCAPES = { n: '\n', t: '\t', r: '\r', '"': '"', '\\': '\\' }

-- expands `${NAME}` and `${NAME:-default}`, leaving other uses of `$` alone
expand = (value, lookup) ->
  value\gsub '%${([^}]*)}', (ref) ->
    name, default = ref\match '^([%a_][%w_]*):%-(.*)$'
    if name
      v = lookup name
      return (v == nil or v == '') and default or v

    name = ref\match '^([%a_][%w_]*)$'
    return nil unless name
    lookup(name) or ''

-- returns the position of the closing double quote at or after pos, if any
closing_quote = (text, pos) ->
  while true
    pos = text\find '[\\"]', pos
    return nil unless pos
    return pos if text\byte(pos) == 34
    pos += 2

-- returns the variables in text. `${NAME}` references are looked up among the
-- variables before them, and then using `lookup(name)`.
parse = (text, lookup = -> nil) ->
  vars = {}
  resolve = (name) ->
    v = vars[name]
    return v if v != nil
    lookup name

  pos = 1
  while pos <= #text
    _, e, name = text\find '^[ \t]*export[ \t]+([%a_][%w_]*)[ \t]*=[ \t]*', pos
    unless e
      _, e, name = text\find '^[ \t]*([%a_][%w_]*)[ \t]*=[ \t]*', pos

    if e
      pos = e + 1
      quote = text\sub pos, pos
      if quote == "'"
        close = text\find "'", pos + 1, true
        if close
          vars[name] = text\sub pos + 1, close - 1
          pos = close + 1
      elseif quote == '"'
        close = closing_quote text, pos + 1
        if close
          value = text\sub(pos + 1, close - 1)\gsub '\\(.)', (c) -> ESCAPES[c] or '\\' .. c
          vars[name] = expand value, resolve
          pos = close + 1
      else
        line_end = text\find('[\r\n]', pos) or #text + 1
        value = text\sub(pos, line_end - 1)\gsub('%s+#.*$', '')\gsub '%s+$', ''
        vars[name] = expand value, resolve
        pos = line_end

    -- anything else on the line is a comment, or doesn't parse
    nl = text\find '\n', pos, true
    pos = nl and nl + 1 or #text + 1

  vars

:parse
