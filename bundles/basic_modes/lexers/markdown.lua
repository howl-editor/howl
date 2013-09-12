-- Copyright 2006-2012 Mitchell mitchell.att.foicica.com. See LICENSE.
-- Markdown LPeg lexer.

local l = lexer
local token, style, color, word_match = l.token, l.style, l.color, l.word_match
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local M = {_NAME = 'markdown'}

-- Whitespace.
local ws = token(l.WHITESPACE, l.space^1)

-- Block elements.
local h6 = token('h6', P('######') * l.any^0)
local h5 = token('h5', P('#####') * l.any^0)
local h4 = token('h4', P('####') * l.any^0)
local h3 = token('h3', P('###') * l.any^0)
local h2 = token('h2', P('##') * l.any^0)
local h1 = token('h1', P('#') * l.any^0)
local header = #P('#') * (h6 + h5 + h4 + h3 + h2 + h1)

local in_blockquote
local blockquote = token(l.STRING, P('>') * P(function(input, index)
  in_blockquote = true
  return index
end) * l.any^0 + P(function(input, index)
  return in_blockquote and index or nil
end) * l.any^1)

local blockcode = token('code', (P(' ')^4 + P('\t')) * l.any^0)

local hr = token('hr', #S('*-_') * P(function(input, index)
  local line = input:gsub(' ', '')
  if line:find('[^\r\n*-_]') then return nil end
  if line:find('^%*%*%*') or line:find('^%-%-%-') or line:find('^___') then
    return index
  end
end) * l.any^1)

local hypertext = l.load('hypertext')
local html_rules = hypertext._RULES
--local html_rule = html_rules['whitespace'] + html_rules['default'] +
--                  html_rules['tag'] + html_rules['entity'] +
--                  html_rules['any_char']
local html_rule = html_rules['default'] + html_rules['tag'] +
                  html_rules['entity'] + html_rules['any_char']
local in_html = false
local html = #P('<') * html_rule^1 * P(function(input, index)
  in_html = true
  return index
end) + P(function(input, index)
  return in_html and index or nil
end) * html_rule^1

local blank = token(l.DEFAULT, l.newline^1 * P(function(input, index)
  in_blockquote = false
  in_html = false
end))

-- Span elements.
local dq_str = token(l.STRING, l.delimited_range('"', nil, true))
local sq_str = token(l.STRING, l.delimited_range("'", nil, true))
local paren_str = token(l.STRING, l.delimited_range('()', nil, true))
local link = token('link', P('!')^-1 * l.delimited_range('[]') *
                           (P('(') * (l.any - S(') \t'))^0 *
                            (l.space^1 * l.delimited_range('"', nil, true))^-1 *
                            ')' + l.space^0 * l.delimited_range('[]')) +
                           P('http://') * (l.any - l.space)^1)
local link_label = ws^0 * token('link_label', l.delimited_range('[]') * ':') *
                   ws * token('link_url', (l.any - l.space)^1) *
                   (ws * (dq_str + sq_str + paren_str))^-1

local strong = token('strong', (P('**') * (l.any - '**')^0 * P('**')^-1) +
                               (P('__') * (l.any - '__')^0 * P('__')^-1))
local em = token('em', l.delimited_range('*', '\\', true) +
                       l.delimited_range('_', '\\', true))
local code = token('code', (P('``') * (l.any - '``')^0 * P('``')^-1) +
                           l.delimited_range('`', nil, true))

local escape = token(l.DEFAULT, P('\\') * 1)

local text_line = (ws + escape + link + strong + em + code + l.any_char)^1

local list = token('list', S('*+-') + R('09') * '.') * ws * text_line

M._rules = {
  {'blank', blank},
  {'html', html},
  {'header', header},
  {'blockquote', blockquote},
  {'blockcode', blockcode},
  {'hr', hr},
  {'link_label', link_label},
  {'list', list},
  {'text_line', text_line},
}

M._LEXBYLINE = true

local font_size = 10
local hstyle = l.style_nothing..{fore = l.colors.red}
M._tokenstyles = {
  {'h6', hstyle},
  {'h5', hstyle..{size = font_size + 1}},
  {'h4', hstyle..{size = font_size + 2}},
  {'h3', hstyle..{size = font_size + 3}},
  {'h2', hstyle..{size = font_size + 4}},
  {'h1', hstyle..{size = font_size + 5}},
  {'code', l.style_embedded..{eolfilled = true}},
  {'hr', l.style_nothing..{back = l.colors.black, eolfilled = true}},
  {'link', l.style_nothing..{underline = true}},
  {'link_url', l.style_nothing..{underline = true}},
  {'link_label', l.style_label},
  {'strong', l.style_nothing..{bold = true}},
  {'em', l.style_nothing..{italic = true}},
  {'list', l.style_constant},
  {'html', l.style_embedded}
}

-- Do not actually embed; just load the styles.
l.embed_lexer(M, hypertext, P(false), P(false))

return M
