howl.aux.lpeg_lexer ->

  comment = capture 'comment', span(';', eol)
  operator = capture 'operator', S'+-*!\\/%^#=<>;:,.(){}[]'
  dq_string = capture 'string', span('"', '"', P'\\')
  number = capture 'number', digit^1
  name = alpha^1 * any({ alpha, digit, S'/-_?'})^0
  identifier = capture 'identifier', name
  keyword = capture 'constant', P':' * P':'^0 * name

  fcall = capture('operator', P'(') * capture('function', name)
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
