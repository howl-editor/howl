lpeg = require 'lpeg'
import lpegx from howl
import P, S, V from lpeg
import space, eof from lpegx

fdecl = S('-=') * '>' * space^0 * eof
hanging_operators = S'([{:=' * space^0 * eof
blocks = space^0 * (P'class' + 'switch' + 'do' + 'with' + 'for' + 'when') * (eof + space^1)
cond_keywords = P'elseif' + 'if' + 'else' + 'while' + 'unless'

indent_pattern = P {
  V('conditionals') + blocks + V('partial_matches')
  partial_matches: hanging_operators + fdecl + (1 * V 'partial_matches')
  conditionals: space^0 * cond_keywords * (eof + space * -V('then'))
  then: space^1 * 'then' * space^1 + (1 * V 'then')
}

dedent_pattern = space^0 * (P'elseif' + 'else' + '}') * (eof + space^1)

prev_non_empty_line = (line) ->
  prev_line = line.previous
  while prev_line and prev_line.empty
    prev_line = prev_line.previous
  prev_line

class MoonscriptMode
  new: =>
    lexer_file = bundle_file 'moonscript_lexer.lua'
    @lexer = bundle_load('moonscript_lexer.moon')

  short_comment_prefix: '--'

  indent_for: (line, indent_level, editor) =>
    prev_line = prev_non_empty_line line

    if prev_line
      return prev_line.indentation + indent_level if indent_pattern\match prev_line.text
      if dedent_pattern\match line.text
        unless r('\\bthen\\b')\match prev_line.text
          return prev_line.indentation - indent_level

      return prev_line.indentation if line.indentation > prev_line.indentation or line.blank

    alignment_adjustment = line.indentation % indent_level
    return line.indentation + alignment_adjustment

  after_newline: (line, editor) =>
    if line\match '^%s*}%s*$'
      wanted_indent = line.indentation
      editor\shift_left!
      new_line = editor.buffer.lines\insert line.nr, ''
      new_line.indentation = wanted_indent

return MoonscriptMode
