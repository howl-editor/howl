-- Copyright 2018 equim. See LICENSE.
-- Pony LPeg lexer.

local l = lexer
local token, style, color, word_match = l.token, l.style, l.color, l.word_match
local P, R, S, V = lpeg.P, lpeg.R, lpeg.S, lpeg.V

local M = {_NAME = 'pony'}

-- Whitespace.
local ws = token(l.WHITESPACE, l.space^1)

-- Comments.
local line_comment = '//' * l.nonnewline^0
local block_comment = P{
  "block_comment";
  block_comment = '/*' *  (V"block_comment" + ((-P'/*') * (-P'*/') * l.any))^0  * P('*/')^-1,
}
local comment = token(l.COMMENT, line_comment + block_comment)

-- Strings.
local dq_str = l.delimited_range('"', '\\', false)
local triple_dq_str = '"""' * (l.any - '"""')^0 * P('"""')^-1
local string = token(l.STRING, triple_dq_str + dq_str)

-- Numbers.
local dec_num = l.digit^1 * ('_' * l.digit^1)^0
local hex_num = '0' * S'xX' * P'_'^-1 * l.xdigit^1 * ('_' * l.xdigit^1)^0
local bin_num = '0' * S'bB' * P'_'^-1 * S'01'^1 * ('_' * S'01'^1)^0
local float = (dec_num * '.' * dec_num * (S'eE' * (P'+' + P'-')^-1 * P'_'^-1 * dec_num)^-1)
  + (dec_num * S'eE' * P'_'^-1 * dec_num)
local chars = l.delimited_range("'", '\\', false)
local number = token(l.NUMBER, float + hex_num + bin_num + dec_num + chars)

-- Keywords.
local keyword = token(l.KEYWORD, word_match({
  'actor',
  'addressof',
  'and',
  'as',
  'be',
  'box',
  'break',
  'class',
  'compile_error',
  'compile_intrinsic',
  'consume',
  'continue',
  'do',
  'digestof',
  'else',
  'elseif',
  'embed',
  'end',
  'error',
  'false',
  'for',
  'fun',
  'if',
  'ifdef',
  'iftype',
  'in',
  'interface',
  'is',
  'isnt',
  'iso',
  'lambda',
  'let',
  'match',
  'new',
  'not',
  'object',
  'or',
  'primitive',
  'recover',
  'ref',
  'repeat',
  'return',
  'struct',
  'tag',
  'then',
  'this',
  'trait',
  'trn',
  'true',
  'try',
  'type',
  'until',
  'use',
  'val',
  'var',
  'where',
  'while',
  'with',
  'xor'
}))

-- Types.
local type = token(l.TYPE, word_match{
  'I8',
  'I16',
  'I32',
  'I64',
  'ILong',
  'ISize',
  'I128',
  'Signed',
  'Pointer',
  'MaybePointer',
  'None',
  'Env',
  'AsioEventID',
  'AsioEventNotify',
  'AsioEvent',
  'F32',
  'F64',
  'Float',
  'Seq',
  'Real',
  'Integer',
  'FloatingPoint',
  'Number',
  'Int',
  'DoNotOptimise',
  'Bool',
  'AmbientAuth',
  'Iterator',
  'SourceLoc',
  'Array',
  'ArrayKeys',
  'ArrayValues',
  'ArrayPairs',
  'Less',
  'Equal',
  'Greater',
  'Compare',
  'HasEq',
  'Equatable',
  'Comparable',
  'Platform',
  'Stringable',
  'ByteSeq',
  'ByteSeqIter',
  'OutStream',
  'StdStream',
  'Any',
  'ReadSeq',
  'ReadElement',
  'U8',
  'U16',
  'U32',
  'U64',
  'ULong',
  'USize',
  'U128',
  'Unsigned',
  'String',
  'StringBytes',
  'StringRunes',
  'StdinNotify',
  'DisposableActor',
  'Stdin'
})

-- Identifiers.
local identifier = token(l.IDENTIFIER, l.word * P"'"^0)


-- Operators.
local operator = token(l.OPERATOR, S('@=!<>+-/*%^&|~.,:;?()[]{}'))

-- Functions.
local func = token(l.FUNCTION, l.word) * #P('(')

-- Classes.
local class_sequence = token(l.KEYWORD,
    P('class') +
    P('actor') +
    P('primitive') +
    P('interface') +
    P('trait') +
    P('type') +
    P('struct'))
  * ws^1 * token(l.CLASS, l.word)

-- Preprocessor.
local preproc_word = word_match{
  'freebsd',
  'linux',
  'osx',
  'posix',
  'windows',
  'x86',
  'arm',
  'lp64',
  'llp64',
  'ilp32',
  'native128',
  'debug'
}
local preproc_conditional = (ws
    + token(l.OPERATOR, S'()')
    + token(l.KEYWORD, word_match{'not', 'and', 'or'})
    + token(l.PREPROCESSOR, preproc_word))^0
local preproc_ifdef_sequence = token(l.KEYWORD, P'ifdef')
  * ws
  * preproc_conditional
local preproc_use_sequence = token(l.KEYWORD, P'use')
  * ws^1
  * (token(l.IDENTIFIER, l.word) * token(l.OPERATOR, P'=') * ws^1)^-1
  * string
  * ws^1
  * token(l.KEYWORD, P'if')
  * ws
  * preproc_conditional
local preproc = preproc_ifdef_sequence + preproc_use_sequence

M._rules = {
  {'whitespace', ws},
  {'class', class_sequence},
  {'preproc', preproc},
  {'keyword', keyword},
  {'type', type},
  {'function', func},
  {'identifier', identifier},
  {'string', string},
  {'comment', comment},
  {'number', number},
  {'operator', operator},
  {'any_char', l.any_char},
}

return M
