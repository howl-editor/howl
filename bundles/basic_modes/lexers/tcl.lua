-- Copyright 2006-2012 Mitchell mitchell.att.foicica.com. See LICENSE.
-- Tcl LPeg lexer.

local l = lexer
local token, style, color, word_match = l.token, l.style, l.color, l.word_match
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local M = {_NAME = 'tcl'}

-- Whitespace.
local ws = token(l.WHITESPACE, l.space^1)

-- Comments.
local comment = token(l.COMMENT, '#' * P(function(input, index)
  local i = index - 2
  while i > 0 and input:find('^[ \t]', i) do i = i - 1 end
  if i < 1 or input:find('^[\r\n;]', i) then return index end
end) * l.nonnewline^0)

-- Strings.
local sq_str = l.delimited_range("'", '\\', true, false, '\n')
local dq_str = l.delimited_range('"', '\\', true, false, '\n')
local regex_str = l.last_char_includes('<>=+-*!@|&,:;?([{') *
                  l.delimited_range('/', '\\', false, false, '\n')
local string = token(l.STRING, sq_str + dq_str) + token(l.REGEX, regex_str)

-- Numbers.
local number = token(l.NUMBER, l.float + l.integer)

-- Keywords.
local keyword = token(l.KEYWORD, word_match{
  'string', 'subst', 'regexp', 'regsub', 'scan', 'format', 'binary', 'list',
  'split', 'join', 'concat', 'llength', 'lrange', 'lsearch', 'lreplace',
  'lindex', 'lsort', 'linsert', 'lrepeat', 'dict', 'if', 'else', 'elseif',
  'then', 'for', 'foreach', 'switch', 'case', 'while', 'continue', 'return',
  'break', 'catch', 'error', 'eval', 'uplevel', 'after', 'update', 'vwait',
  'proc', 'rename', 'set', 'lset', 'lassign', 'unset', 'namespace', 'variable',
  'upvar', 'global', 'trace', 'array', 'incr', 'append', 'lappend', 'expr',
  'file', 'open', 'close', 'socket', 'fconfigure', 'puts', 'gets', 'read',
  'seek', 'tell', 'eof', 'flush', 'fblocked', 'fcopy', 'fileevent', 'source',
  'load', 'unload', 'package', 'info', 'interp', 'history', 'bgerror',
  'unknown', 'memory', 'cd', 'pwd', 'clock', 'time', 'exec', 'glob', 'pid',
  'exit'
})

-- Identifiers.
local identifier = token(l.IDENTIFIER, l.word)

-- Variables.
local variable = token(l.VARIABLE, S('$@') * P('$')^-1 * l.word)

-- Operators.
local operator = token(l.OPERATOR, S('<>=+-*/!@|&.,:;?()[]{}'))

M._rules = {
  {'whitespace', ws},
  {'keyword', keyword},
  {'identifier', identifier},
  {'string', string},
  {'comment', comment},
  {'number', number},
  {'variable', variable},
  {'operator', operator},
  {'any_char', l.any_char},
}

M._foldsymbols = {
  _patterns = {'[{}]', '#'},
  [l.OPERATOR] = {['{'] = 1, ['}'] = -1},
  [l.COMMENT] = {['#'] = l.fold_line_comments('#')}
}

return M
