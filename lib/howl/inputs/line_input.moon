-- Copyright 2012-2013 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

import Matcher from howl.util

class LineInput
  new: (@title, buffer, @lines = buffer.lines) =>
    @completion_options = title: @title, list: column_styles: { 'string' }
    @items = [{tostring(l.nr), l.chunk} for l in *@lines]
    buffer\lex buffer.size

  complete: (text) =>
    matches = [i for i in *@items when i[2].text\umatch text]
    return matches, @completion_options

  value_for: (value) =>
    nr = tonumber value
    for line in *@lines
      return line if nr == line.nr

    value

  should_complete: => true
  close_on_cancel: => true

howl.inputs.register 'line', LineInput
