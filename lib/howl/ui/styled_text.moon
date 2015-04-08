-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

append = table.insert

local mt

mt = {
  __tostring: => @text,

  __concat: (op1, op2) ->
    text = tostring(op1) .. tostring(op2)
    return text unless typeof(op1) == "StyledText" and typeof(op2) == "StyledText"

    styles = moon.copy op1.styles
    offset = #op1.text
    i = 1

    while op2.styles[i]
      append styles, op2.styles[i] + offset
      i += 1
      append styles, op2.styles[i]
      i += 1
      append styles, op2.styles[i] + offset
      i += 1

    return setmetatable {:text, :styles}, mt

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
