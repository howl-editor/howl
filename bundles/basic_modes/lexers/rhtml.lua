-- Copyright 2006-2012 Mitchell mitchell.att.foicica.com. See LICENSE.
-- RHTML LPeg lexer.

local l = lexer
local token, style, color, word_match = l.token, l.style, l.color, l.word_match
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local M = {_NAME = 'rhtml'}

-- Embedded in HTML.
local html = l.load('hypertext')
M._lexer = html

-- Embedded Ruby.
local ruby = l.load('rails')
local ruby_start_rule = token('rhtml_tag', '<%' * P('=')^-1)
local ruby_end_rule = token('rhtml_tag', '%>')
l.embed_lexer(html, ruby, ruby_start_rule, ruby_end_rule, true)

M._tokenstyles = {
  {'rhtml_tag', l.style_embedded},
}

local _foldsymbols = html._foldsymbols
_foldsymbols._patterns[#_foldsymbols._patterns + 1] = '<%%'
_foldsymbols._patterns[#_foldsymbols._patterns + 1] = '%%>'
_foldsymbols.rhtml_tag = {['<%'] = 1, ['%>'] = -1}
M._foldsymbols = _foldsymbols

return M
