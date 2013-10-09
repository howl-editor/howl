howl.aux.lpeg_lexer ->

  comment = capture 'comment', span(';', eol)
  operator = capture 'operator', S'/.%^#,(){}[]'
  dq_string = capture 'string', span('"', '"', P'\\')
  number = capture 'number', digit^1 * alpha^-1

  delimiter = any { space, S'/.,(){}[]^#' }
  name = complement(delimiter)^1
  identifier = capture 'identifier', name
  keyword = capture 'constant', P':' * P':'^0 * name

  fcall = capture('operator', P'(') * capture('function', complement(delimiter))^1
  specials = capture 'special', word { 'true', 'false' }

  any {
    dq_string,
    comment,
    number,
    fcall,
    keyword,
    specials,
    identifier,
    operator,
  }
