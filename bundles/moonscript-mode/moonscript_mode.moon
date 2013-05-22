-- indent_pattern [, unless_match_pattern]
indent_patterns = {
  '[-=]>%s*$', -- fdecls
  '[([{:=]%s*$' -- hanging operators
  r'^\\s*\\b(class|switch|do|with|for|when)\\b', -- block starters
  { r'^\\s*\\b(elseif|if|while|unless)\\b', '%sthen%s*'}, -- conditionals
  '^%s*else%s*$',
  { '=%s*if%s', '%sthen%s*'} -- if used as rvalue

}

dedent_patterns = {
  r'^\\s*(else|\\})\\s*$',
  { '^%s*elseif%s', '%sthen%s*' }
}

is_match = (text, patterns) ->
  for p in *patterns
    neg_match = nil
    if type(p) == 'table'
      p, neg_match = p[1], p[2]

    match = text\umatch p
    if text\umatch(p) and (not neg_match or not text\umatch neg_match)
      return true

  false

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
      return prev_line.indentation + indent_level if is_match prev_line.text, indent_patterns
      return prev_line.indentation - indent_level if is_match line.text, dedent_patterns
      return prev_line.indentation if line.indentation > prev_line.indentation or line.blank

    alignment_adjustment = line.indentation % indent_level
    return line.indentation + alignment_adjustment

  after_newline: (line, editor) =>
    if line\match '^%s*}%s*$'
      wanted_indent = line.indentation
      editor\shift_left!
      new_line = editor.buffer.lines\insert line.nr, ''
      new_line.indentation = wanted_indent
      with editor.cursor
        .line = line.nr
        .column = wanted_indent + 1

return MoonscriptMode
