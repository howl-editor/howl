-- Copyright 2006-2012 gwash. See LICENSE.
-- Archlinux PKGBUILD LPeg lexer.

local l = lexer
local token, style, color, word_match = l.token, l.style, l.color, l.word_match
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local M = {_NAME = 'pkgbuild'}

-- Whitespace.
local ws = token(l.WHITESPACE, l.space^1)

-- Comments.
local comment = token(l.COMMENT, '#' * l.nonnewline^0)

-- Strings.
local sq_str = l.delimited_range("'", nil, true)
local dq_str = l.delimited_range('"', '\\', true)
local ex_str = l.delimited_range('`', '\\', true)
local heredoc = '<<' * P(function(input, index)
  local s, e, _, delimiter =
    input:find('(["\']?)([%a_][%w_]*)%1[\n\r\f;]+', index)
  if s == index and delimiter then
    local _, e = input:find('[\n\r\f]+'..delimiter, e)
    return e and e + 1 or #input + 1
  end
end)
local string = token(l.STRING, sq_str + dq_str + ex_str + heredoc)

-- Numbers.
local number = token(l.NUMBER, l.float + l.integer)

-- Keywords.
local keyword = token(l.KEYWORD, word_match({
  'patch', 'cd', 'make', 'patch', 'mkdir', 'cp', 'sed', 'install', 'rm',
  'if', 'then', 'elif', 'else', 'fi', 'case', 'in', 'esac', 'while', 'for',
  'do', 'done', 'continue', 'local', 'return', 'git', 'svn', 'co', 'clone',
  'gconf-merge-schema', 'msg', 'echo', 'ln', 'chmod', 'find',
  -- Operators.
  '-a', '-b', '-c', '-d', '-e', '-f', '-g', '-h', '-k', '-p', '-r', '-s', '-t',
  '-u', '-w', '-x', '-O', '-G', '-L', '-S', '-N', '-nt', '-ot', '-ef', '-o',
  '-z', '-n', '-eq', '-ne', '-lt', '-le', '-gt', '-ge', '-Np', '-i'
}, '-'))

-- Functions.
local func = token(l.FUNCTION, word_match{'build', 'prepare', 'package', 'check'})

local constant = token(l.CONSTANT, word_match{
  'pkgname', 'pkgver', 'pkgrel', 'pkgdesc', 'arch', 'url',
  'license', 'optdepends', 'depends', 'makedepends', 'provides',
  'conflicts', 'replaces', 'install', 'source', 'md5sums',
  'pkgdir', 'srcdir', 'sha256sums', 'options', 'groups'
})

-- Identifiers.
local identifier = token(l.IDENTIFIER, l.word)

-- Variables.
local variable = token(l.VARIABLE,
                       '$' * (S('!#?*@$') +
                       l.delimited_range('()', nil, true, false, '\n') +
                       l.delimited_range('[]', nil, true, false, '\n') +
                       l.delimited_range('{}', nil, true, false, '\n') +
                       l.delimited_range('`', nil, true, false, '\n') +
                       l.digit^1 + l.word))

-- Operators.
local operator = token(l.OPERATOR, S('=!<>+-/*^~.,:;?()[]{}'))

M._rules = {
  {'whitespace', ws},
  {'comment', comment},
  {'string', string},
  {'number', number},
  {'keyword', keyword},
  {'function', func},
  {'constant', constant},
  {'identifier', identifier},
  {'variable', variable},
  {'operator', operator},
  {'any_char', l.any_char},
}

M._foldsymbols = {
  _patterns = {'[%(%){}]', '#'},
  [l.OPERATOR] = {['('] = 1, [')'] = -1, ['{'] = 1, ['}'] = -1},
  [l.COMMENT] = {['#'] = l.fold_line_comments('#')}
}

return M
