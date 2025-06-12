-- Terraform/HCL mode for Howl Editor
-- License: MIT

class TerraformMode
  new: =>
    @lexer = bundle_load('terraform_lexer')

  default_config:
    use_tabs: false
    tab_width: 2
    cursor_line_highlighted: true

  comment_syntax: '#'

  auto_pairs: {
    '(': ')',
    '[': ']',
    '{': '}',
    '"': '"'
  }

  indentation:
    more_after: {
      r'{\s*$',           -- Opening brace
      r'=\s*\{\s*$',      -- Assignment to block
      r'=\s*\[\s*$'       -- Assignment to list
    }
    less_for: {
      r'^\s*}',          -- Closing brace
      r'^\s*]'           -- Closing bracket
    }

  code_blocks:
    multiline: {
      { r'\{\s*$', r'^\s*}', '}' },         -- Block delimited by braces
      { r'\[\s*$', r'^\s*]', ']' }         -- List delimited by brackets
    }

  structure: (editor) =>
    items = {}
    for line_nr = 1, #editor.buffer.lines
      line = editor.buffer.lines[line_nr]
      -- Match resource blocks
      resource_match = line.text\match('^%s*resource%s+\"([^\"]+)\"%s+\"([^\"]+)\"')
      if resource_match
        type_name, resource_name = resource_match\match('\"([^\"]+)\"%s+\"([^\"]+)\"')
        if type_name and resource_name
          items[#items + 1] = {
            :line_nr,
            name: "#{type_name}.#{resource_name}",
            type: 'resource'
          }

      -- Match data blocks
      data_match = line.text\match('^%s*data%s+\"([^\"]+)\"%s+\"([^\"]+)\"')
      if data_match
        type_name, data_name = data_match\match('\"([^\"]+)\"%s+\"([^\"]+)\"')
        if type_name and data_name
          items[#items + 1] = {
            :line_nr,
            name: "data.#{type_name}.#{data_name}",
            type: 'data'
          }

      -- Match variable blocks
      variable_match = line.text\match('^%s*variable%s+\"([^\"]+)\"')
      if variable_match
        var_name = variable_match\match('\"([^\"]+)\"')
        if var_name
          items[#items + 1] = {
            :line_nr,
            name: "var.#{var_name}",
            type: 'variable'
          }

      -- Match output blocks
      output_match = line.text\match('^%s*output%s+\"([^\"]+)\"')
      if output_match
        output_name = output_match\match('\"([^\"]+)\"')
        if output_name
          items[#items + 1] = {
            :line_nr,
            name: "output.#{output_name}",
            type: 'output'
          }

      -- Match module blocks
      module_match = line.text\match('^%s*module%s+\"([^\"]+)\"')
      if module_match
        module_name = module_match\match('\"([^\"]+)\"')
        if module_name
          items[#items + 1] = {
            :line_nr,
            name: "module.#{module_name}",
            type: 'module'
          }

    items
