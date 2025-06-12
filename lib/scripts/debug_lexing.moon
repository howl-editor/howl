-- Copyright 2024 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)
--
-- Debug script for testing lexers within Howl
-- Usage: ./src/howl --run lib/scripts/debug_lexing.moon <file_path>
-- Returns lexer output in JSON format

{:mode, :bundle} = howl
import File from howl.io
json = require 'lunajson'

args = {...}

unless #args >= 1
  print 'Usage: debug_lexing.moon <file_path>'
  print 'Returns the lexer output for the specified file in JSON format'
  os.exit(1)

file_path = args[1]
file = File file_path

unless file.exists
  print "Error: File '#{file_path}' does not exist"
  os.exit(1)

bundle.load_all!

-- Get the mode for this file type
file_mode = mode.for_file file

unless file_mode
  print "Error: No mode found for file '#{file_path}'"
  os.exit(1)

-- Check if the mode has a lexer
unless file_mode.lexer
  print "Error: Mode '#{file_mode.name}' does not have a lexer"
  os.exit(1)

-- Read the file content
content = file.contents

-- Helper to get line number from byte offset
get_line_number_from_offset = (text_content, target_offset) ->
  if target_offset <= 0 return 1 -- Should ideally be an error or 1 as a fallback
  -- Ensure target_offset is within reasonable bounds (1 to length + 1)
  target_offset = math.max(1, math.min(target_offset, #text_content + 1))

  line_count = 1
  for i = 1, target_offset - 1
    if i <= #text_content and text_content\sub(i, i) == '\n'
      line_count += 1
  return line_count

-- Validate lexer output
-- Returns true if valid, false if an error is found (stops on first error)
validate_output = (output, file_content_for_lines, base_offset = 0, indent_level = 0) ->
  indent = string.rep('  ', indent_level)

  i = 1
  while i <= #output
    start_pos = output[i]
    style_or_sub_lex = output[i+1]
    end_pos_or_sub_lex_type = output[i+2]

    line_nr = "<unknown>"
    if type(start_pos) == 'number' and start_pos >= 1
      line_nr = get_line_number_from_offset file_content_for_lines, base_offset + start_pos
    else -- Try to get a line based on previous token if current start_pos is invalid
      if i > 3 and type(output[i-3]) == 'number' and output[i-3] >= 1
        line_nr = get_line_number_from_offset file_content_for_lines, base_offset + output[i-3]
      line_nr = "#{line_nr} (approx. due to invalid start_pos)"

    triplet_repr = json.encode {start_pos, style_or_sub_lex, end_pos_or_sub_lex_type}
    error_message = nil
    matched_content_str = nil

    if type(start_pos) != 'number' or start_pos < 1
      error_message = "Start position is not a positive number (1-based)."
    elseif type(style_or_sub_lex) == 'table' -- Sub-lexing
      if type(end_pos_or_sub_lex_type) != 'string' or not end_pos_or_sub_lex_type\match "^inline%|"
        error_message = "Sub-lexing type is invalid (expected 'inline|style')."
      -- Recursively validate sub-lexed output. base_offset for sub-lexer is current start_pos -1.
      elseif type(start_pos) == 'number' and start_pos >=1 -- only recurse if start_pos is somewhat valid
        unless validate_output(style_or_sub_lex, file_content_for_lines, base_offset + start_pos - 1, indent_level + 1)
          return false -- Error found in sub-lex, stop.

    elseif type(style_or_sub_lex) == 'string' -- Standard styling
      if type(end_pos_or_sub_lex_type) != 'number'
        error_message = "End position is not a number."
      elseif end_pos_or_sub_lex_type < start_pos
         -- Note: lexer end is exclusive, so start_pos == end_pos_or_sub_lex_type means empty token, which is valid
        error_message = "End position (#{end_pos_or_sub_lex_type}) is less than start position (#{start_pos})."

      if not error_message and type(start_pos) == 'number' and type(end_pos_or_sub_lex_type) == 'number' and start_pos >=1 and end_pos_or_sub_lex_type >= start_pos
        -- Extract the content. Lexer positions are 1-based. end_pos is exclusive.
        -- string\sub is inclusive for end index.
        actual_char_start_offset = base_offset + start_pos
        actual_char_end_offset = base_offset + end_pos_or_sub_lex_type - 1
        if actual_char_start_offset <= actual_char_end_offset -- Ensure valid range for sub
          actual_char_end_offset = math.min(actual_char_end_offset, #file_content_for_lines) -- cap at content length
          if actual_char_start_offset <= #file_content_for_lines
             matched_content_str = file_content_for_lines\sub(actual_char_start_offset, actual_char_end_offset)

    else -- Invalid type for style/sub-lex
      error_message = "Style/Sub-lex element (output[#{i+1}]) is not a string or table."

    if error_message
      print "#{indent}Error on line #{line_nr}: #{error_message}"
      print "#{indent}Triplet: #{triplet_repr}"
      if matched_content_str
        print "#{indent}Content: '#{matched_content_str}'"
      else
        -- Try to show content around the start_pos if possible, even if end_pos was bad
        if type(start_pos) == 'number' and start_pos >=1
          ctx_start = math.max(1, base_offset + start_pos - 5)
          ctx_end = math.min(#file_content_for_lines, base_offset + start_pos + 10)
          if ctx_start <= ctx_end and ctx_start <= #file_content_for_lines
            context_snip = file_content_for_lines\sub(ctx_start, ctx_end)
            print "#{indent}Context near start_pos(#{base_offset + start_pos}): '...#{context_snip}...\'"

      return false -- Stop on first error

    i += 3
  return true -- All triplets validated successfully

-- Run the lexer
lexer_output = file_mode.lexer content

-- Validate the output
if lexer_output and #lexer_output > 0
  print "Validating lexer output..."
  if not validate_output lexer_output, content
    print "Validation finished with errors."
    os.exit 1
  else
    print "Validation successful."
else
  print "Lexer produced no output or output is nil."


-- Create result structure
result = {
  file: file_path,
  mode: file_mode.name,
  content_length: #content,
  lexer_output: lexer_output
}

-- Output as JSON
print json.encode result
