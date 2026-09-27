-- Copyright 2026 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

-- Renders markdown as styled text, for displaying documentation. The markup is
-- removed and the content styled, with fenced code highlighted by the lexer
-- of its language. Only what documentation typically uses is handled, and
-- the line structure is kept as is.

{:mode} = howl
{:StyledText} = howl.ui
append = table.insert

MAX_RULE_WIDTH = 80
RULE_CHAR = '─'

entities = {
  ['&nbsp;']: ' ',
  ['&lt;']: '<',
  ['&gt;']: '>',
  ['&amp;']: '&',
  ['&quot;']: '"',
  ['&#39;']: "'",
}

-- the styles are named as by the markdown lexer, which themes are made for
emphasis_styles = { 'strong', 'emphasis' }

local inline

-- splits inline markdown into text tokens, with optional spans, and
-- emphasis delimiter tokens
tokenize = (s) ->
  tokens = {}
  add_text = (text, spans) -> append tokens, :text, :spans
  i, n = 1, #s

  while i <= n
    c = s\sub i, i
    entity = c == '&' and s\match('^&#?%w+;', i)

    if c == '\\' and s\sub(i + 1, i + 1)\match '^%p$'
      add_text s\sub(i + 1, i + 1)
      i += 2

    elseif c == '`'
      ticks = s\match '^`+', i
      close = s\find ticks, i + #ticks, true
      if close
        code = s\sub i + #ticks, close - 1
        code = code\sub(2, -2) if code\match '^ .*%S.* $'
        add_text code, { {1, 'embedded', #code + 1} }
        i = close + #ticks
      else
        add_text ticks
        i += #ticks

    elseif entity and entities[entity]
      add_text entities[entity]
      i += #entity

    elseif c == '['
      label, after = s\match '^%[([^%]]*)%]()', i
      target_end = label and (s\match('^%b()()', after) or s\match('^%b[]()', after))
      if target_end
        text, spans = inline label
        table.insert spans, 1, {1, 'link_label', #text + 1}
        add_text text, spans
        i = target_end
      else
        add_text c
        i += 1

    elseif c == '*' or c == '_'
      count = math.min #s\match("^%#{c}+", i), 2
      prev = i > 1 and s\sub(i - 1, i - 1) or ' '
      nxt = s\sub i + count, i + count
      nxt = ' ' if nxt == ''
      can_open = not nxt\match '%s'
      can_close = not prev\match '%s'
      -- underscores within words, as in snake_case, are not emphasis
      if c == '_'
        can_open = can_open and not prev\match '%w'
        can_close = can_close and not nxt\match '%w'
      append tokens, delim: c, :count, :can_open, :can_close, text: c\rep(count)
      i += count

    else
      next_special = s\find('[\\`&%[*_]', i + 1) or n + 1
      add_text s\sub(i, next_special - 1)
      i = next_special

  tokens

-- pairs up emphasis delimiters; unpaired ones are kept as text
match_delimiters = (tokens) ->
  openers = {}
  for t in *tokens
    continue unless t.delim
    if t.can_close
      for k = #openers, 1, -1
        o = openers[k]
        if o.delim == t.delim and o.count == t.count
          o.closer = t
          t.opener = o
          openers[j] = nil for j = #openers, k, -1
          break

    append openers, t if t.can_open and not t.opener

-- returns the text and spans for inline markdown. Spans are `{start, style,
-- end}` byte offsets, with enclosing spans before those they enclose.
inline = (s) ->
  tokens = tokenize s
  match_delimiters tokens
  parts, spans, len = {}, {}, 0

  for t in *tokens
    if t.closer
      t.start = len + 1
    elseif t.opener
      append spans, {t.opener.start, emphasis_styles[t.count], len + 1}
    else
      for span in *(t.spans or {})
        append spans, {span[1] + len, span[2], span[3] + len}
      append parts, t.text
      len += #t.text

  table.sort spans, (a, b) -> a[1] < b[1] or (a[1] == b[1] and a[3] > b[3])
  table.concat(parts), spans

-- a line starting with `prefix` followed by inline markdown, with the part of
-- the prefix from `marker_start` styled as an operator
prefixed = (prefix, marker_start, s) ->
  text, spans = inline s
  shifted = [{span[1] + #prefix, span[2], span[3] + #prefix} for span in *spans]
  table.insert shifted, 1, {marker_start, 'operator', #prefix\match('^(.-)%s*$') + 1}
  prefix .. text, shifted

is_rule = (line) ->
  stripped = line\gsub '%s', ''
  (stripped\match('^%-%-%-+$') or stripped\match('^%*%*%*+$') or stripped\match('^___+$')) != nil

fence_start = (line) ->
  fence, info = line\match '^%s*(```+)%s*(.-)%s*$'
  unless fence
    fence, info = line\match '^%s*(~~~+)%s*(.-)%s*$'
  fence, info and info\match('^%S*')

code_block = (lines, lang) ->
  code = table.concat lines, '\n'
  return nil if code.is_blank

  spans = { {1, 'embedded', #code + 1} }
  m = lang != '' and mode.by_name lang
  if m and m.lexer
    styles = m.lexer code, nil, sub_lexing: true
    append spans, {1, styles, "#{m.name}|embedded"} if #styles > 0
  text: code, :spans

-- the width of the widest line, within limits
rule_width = (items) ->
  width = 3
  for item in *items
    continue if item.rule
    for line in (item.text .. '\n')\gmatch '([^\n]*)\n'
      width = math.max width, line.ulen
  math.min width, MAX_RULE_WIDTH

(text) ->
  items = {}
  add = (line_text, spans) -> append items, text: line_text, spans: spans or {}
  local fence, lang, code
  -- the indentation of list item content, beyond which indented code starts
  list_indent = 0
  prev_blank = true
  in_code = false

  for line in (text\gsub('\r', '') .. '\n')\gmatch '([^\n]*)\n'
    if fence
      closing = line\match '^%s*([`~]+)%s*$'
      if closing and closing\sub(1, 1) == fence\sub(1, 1) and #closing >= #fence
        append items, code_block(code, lang)
        fence = nil
      else
        append code, line
      continue

    if line.is_blank
      add '' unless prev_blank
      prev_blank = true
      continue

    indent = #line\match '^%s*'
    if indent >= list_indent + 4 and (prev_blank or in_code)
      add line, { {indent + 1, 'embedded', #line + 1} }
      in_code = true
      prev_blank = false
      continue

    in_code = false
    prev_blank = false
    fence, lang = fence_start line
    if fence
      code = {}
      continue

    if is_rule line
      append items, rule: true
      list_indent = 0
      continue

    hashes, title = line\match '^ ? ? ?(#+)%s+(.-)%s*$'
    if hashes and #hashes <= 6
      title_text, spans = inline title\gsub('%s+#+$', '')
      table.insert spans, 1, {1, "h#{math.min #hashes, 3}", #title_text + 1}
      add title_text, spans
      list_indent = 0
      continue

    lead, marker, gap, rest = line\match '^(%s*)([-*+])(%s+)(.*)$'
    if marker
      add prefixed "#{lead}•#{gap}", #lead + 1, rest
      list_indent = #lead + #marker + #gap
      continue

    lead, number, gap, rest = line\match '^(%s*)(%d+[.)])(%s+)(.*)$'
    if number
      add prefixed lead .. number .. gap, #lead + 1, rest
      list_indent = #lead + #number + #gap
      continue

    lead, rest = line\match '^(%s*)>%s?(.*)$'
    if lead
      add prefixed "#{lead}│ ", #lead + 1, rest
      continue

    list_indent = 0 if indent == 0
    add inline(line)

  if fence
    append items, code_block(code, lang)

  while #items > 0 and items[#items].text == ''
    items[#items] = nil

  width = rule_width items
  parts, styles, len = {}, {}, 0
  for i, item in ipairs items
    if i > 1
      append parts, '\n'
      len += 1

    if item.rule
      rule = RULE_CHAR\rep width
      item = text: rule, spans: { {1, 'comment', #rule + 1} }

    for span in *item.spans
      append styles, span[1] + len
      append styles, span[2]
      append styles, type(span[3]) == 'number' and span[3] + len or span[3]

    append parts, item.text
    len += #item.text

  StyledText table.concat(parts), styles
