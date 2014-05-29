-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE.md)

mt = {
  __tostring: => @text,
  __concat: (op1, op2) -> tostring(op1) .. tostring(op2),
  __type: 'StyledText',
  __len: => #@text

  __eq: (op1, op2) ->
    return false unless op1.text == op2.text
    st1, st2 = op1.styles, op2.styles
    for i = 1, #st1
      return false unless st1[i] == st2[i]

    true

  __index: (k) =>
    v = @text[k]

    if v != nil
      return v unless type(v) == 'function'
      return (_, ...) -> v @text, ...
}

(text, styles) ->
    setmetatable {:text, :styles}, mt

