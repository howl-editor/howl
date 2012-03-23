-- Copyright 2006-2012 Mitchell mitchell.att.foicica.com. See LICENSE.
-- D LPeg lexer.
-- Heavily modified by Brian Schott (SirAlaran).

local l = lexer
local token, style, color, word_match = l.token, l.style, l.color, l.word_match
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local M = { _NAME = 'dmd' }

-- Whitespace.
local ws = token(l.WHITESPACE, l.space^1)

-- Comments.
local line_comment = '//' * l.nonnewline_esc^0
local block_comment = '/*' * (l.any - '*/')^0 * P('*/')^-1
local nested_comment = l.nested_pair('/+', '+/', true)
local comment = token(l.COMMENT, line_comment + block_comment + nested_comment)

-- Strings.
local sq_str = l.delimited_range("'", '\\', true, false, '\n') * S('cwd')^-1
local dq_str = l.delimited_range('"', '\\', true, false, '\n') * S('cwd')^-1
local lit_str = 'r' * l.delimited_range('"', nil, true, false, '\n') *
                S('cwd')^-1
local bt_str = l.delimited_range('`', '\\', nil, false, '\n') * S('cwd')^-1
local hex_str = 'x' * l.delimited_range('"', '\\', nil, false, '\n') *
                S('cwd')^-1
local other_hex_str = '\\x' * (l.xdigit * l.xdigit)^1
local del_str = l.nested_pair('q"[', ']"', true) +
                l.nested_pair('q"(', ')"', true) +
                l.nested_pair('q"{', '}"', true) +
                l.nested_pair('q"<', '>"', true) +
                P('q') * l.nested_pair('{', '}', true)
local string = token(l.STRING, del_str + sq_str + dq_str + lit_str + bt_str +
                               hex_str + other_hex_str)

-- Numbers.
local dec = l.digit^1 * ('_' * l.digit^1)^0
local bin_num = '0' * S('bB') * S('01_')^1
local oct_num = '0' * S('01234567_')^1
local integer = S('+-')^-1 * (l.hex_num + oct_num + bin_num + dec)
local number = token(l.NUMBER, (l.float + integer) * S('uUlLdDfFi')^-1)

-- Keywords.
local keyword = token(l.KEYWORD, word_match {
  'abstract', 'align', 'asm', 'assert', 'auto', 'body', 'break', 'case', 'cast',
  'catch', 'const', 'continue', 'debug', 'default', 'delete',
  'deprecated', 'do', 'else', 'extern', 'export', 'false', 'final', 'finally',
  'for', 'foreach', 'foreach_reverse', 'goto', 'if', 'import', 'immutable',
  'in', 'inout', 'invariant', 'is', 'lazy', 'macro', 'mixin', 'new', 'nothrow',
  'null', 'out', 'override', 'pragma', 'private', 'protected', 'public', 'pure',
  'ref', 'return', 'scope', 'shared', 'static', 'super', 'switch',
  'synchronized', 'this', 'throw','true', 'try', 'typeid', 'typeof', 'unittest',
  'version', 'volatile', 'while', 'with', '__gshared', '__thread', '__traits'
})

-- Types.
local type = token(l.TYPE, word_match {
  'alias', 'bool', 'byte', 'cdouble', 'cent', 'cfloat', 'char', 'class',
  'creal', 'dchar', 'delegate', 'double', 'enum', 'float', 'function',
  'idouble', 'ifloat', 'int', 'interface', 'ireal', 'long', 'module', 'package',
  'ptrdiff_t', 'real', 'short', 'size_t', 'struct', 'template', 'typedef',
  'ubyte', 'ucent', 'uint', 'ulong', 'union', 'ushort', 'void', 'wchar',
  'string', 'wstring', 'dstring', 'hash_t', 'equals_t'
})

-- Constants.
local constant = token(l.CONSTANT, word_match {
  '__FILE__', '__LINE__', '__DATE__', '__EOF__', '__TIME__', '__TIMESTAMP__',
  '__VENDOR__', '__VERSION__'
})

local class_sequence = token(l.TYPE, P('class') + P('struct')) * ws^1 *
                                     token(l.CLASS, l.word)

-- Identifiers.
local identifier = token(l.IDENTIFIER, l.word)

-- Operators.
local operator = token(l.OPERATOR, S('?=!<>+-*$/%&|^~.,;()[]{}'))

-- Properties.
local properties = (type + identifier + operator) * token(l.OPERATOR, '.') *
  token(l.VARIABLE, word_match {
    'alignof', 'dig', 'dup', 'epsilon', 'idup', 'im', 'init', 'infinity',
    'keys', 'length', 'mangleof', 'mant_dig', 'max', 'max_10_exp', 'max_exp',
    'min', 'min_normal', 'min_10_exp', 'min_exp', 'nan', 'offsetof', 'ptr',
    're', 'rehash', 'reverse', 'sizeof', 'sort', 'stringof', 'tupleof',
    'values'
  })

-- Preprocs.
local annotation = token('annotation', '@' * l.word^1)
local preproc = token(l.PREPROCESSOR, '#' * l.nonnewline^0)

-- Traits.
local traits_list = token('traits', word_match {
  'isAbstractClass', 'isArithmetic', 'isAssociativeArray', 'isFinalClass',
  'isFloating', 'isIntegral', 'isScalar', 'isStaticArray', 'isUnsigned',
  'isVirtualFunction', 'isAbstractFunction', 'isFinalFunction',
  'isStaticFunction', 'isRef', 'isOut', 'isLazy', 'hasMember', 'identifier',
  'getMember', 'getOverloads', 'getVirtualFunctions', 'parent',
  'classInstanceSize', 'allMembers', 'derivedMembers', 'isSame', 'compiles'
})

-- versions
local versions_list = token('versions', word_match {
  'AIX', 'all', 'Alpha', 'ARM', 'BigEndian', 'BSD', 'Cygwin', 'D_Coverage',
  'D_Ddoc', 'DigitalMars', 'D_InlineAsm_X86', 'D_InlineAsm_X86_64', 'D_LP64',
  'D_NET','D_PIC','D_Version2', 'FreeBSD', 'GNU', 'HPPA', 'HPPA64', 'Hurd',
  'IA64', 'LDC', 'linux', 'LittleEndian', 'MinGW', 'MIPS', 'MIPS64', 'none',
  'OpenBSD', 'OSX', 'Posix', 'PPC', 'PPC64', 'S390', 'S390X', 'SDC', 'SH',
  'SH64', 'SkyOS', 'Solaris', 'SPARC', 'SPARC64', 'SysV3', 'SysV4', 'unittest',
  'Win32', 'Win64', 'Windows', 'X86', 'X86_64'
})

local versions = token(l.KEYWORD, 'version') * l.space^0 *
                 token(l.OPERATOR, '(') * l.space^0 * versions_list


local traits = token(l.KEYWORD, '__traits') * l.space^0 *
               token(l.OPERATOR, '(') * l.space^0 * traits_list

local func = token(l.FUNCTION, l.word) *
             #(l.space^0 * (P('!') * l.word^-1 * l.space^-1)^-1 * P('('))

M._rules = {
  { 'whitespace', ws },
  { 'class', class_sequence },
  { 'traits', traits },
  { 'versions', versions },
  { 'keyword', keyword },
  { 'variable', properties },
  { 'type', type },
  { 'function', func},
  { 'constant', constant },
  { 'string', string },
  { 'identifier', identifier },
  { 'comment', comment },
  { 'number', number },
  { 'preproc', preproc },
  { 'operator', operator },
  { 'annotation', annotation },
  { 'any_char', l.any_char },
}

M._tokenstyles = {
  { 'annotation', l.style_preproc },
  { 'traits', l.style_definition },
  { 'versions', l.style_constant },
}

M._foldsymbols = {
  _patterns = { '[{}]', '/[*+]', '[*+]/', '//' },
  [l.OPERATOR] = { ['{'] = 1, ['}'] = -1 },
  [l.COMMENT] = {
    ['/*'] = 1, ['*/'] = -1, ['/+'] = 1, ['+/'] = -1,
    ['//'] = l.fold_line_comments('//')
  }
}

return M
