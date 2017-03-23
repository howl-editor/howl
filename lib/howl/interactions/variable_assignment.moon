--- Copyright 2012-2017 The Howl Developers
--- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import config, interact from howl
import StyledText from howl.ui

append = table.insert

stringify = (value, to_s) ->
  return to_s(value) if type(value) != 'table'
  [stringify o, to_s for o in *value]

option_completions = (def) ->
  options = def.options
  options = options! if callable options
  options = stringify options, def.tostring or tostring

  table.sort options, (a, b) ->
    return a < b if type(a) != 'table'
    return a[1] < b[1]

  columns = { { header: 'Option', style: 'string' } }
  if type(options[1]) == 'table'
    append columns, { header: 'Description', style: 'comment' }
  return options, columns

option_current_value = (def, options, current_buffer) ->
  cur_val = tostring current_buffer.config[def.name] or config.get def.name
  for option in *options
    if option == cur_val or (type(option) == 'table' and option[1] == cur_val)
      return option

scope_str = (scope, layer=nil) ->
  scope ..= "[#{layer}]" if layer
  return scope

scope_items = (def, buffer) ->
  mode_layer = buffer and buffer.mode.config_layer
  to_s = def.tostring or tostring
  items = {
    { scope_str('global'), to_s(config[def.name]), '',
      scope: 'global', quick_select: scope_str('global') .. '=' }
  }
  return items if def.scope == 'global' or not buffer

  append items,
    { scope_str('global', mode_layer), to_s(buffer.mode.config[def.name]), '',
      scope: 'global', layer: mode_layer, quick_select: scope_str('global', mode_layer) .. '='}

  append items,
    { scope_str('buffer'), to_s(buffer.config[def.name]), buffer.title,
      scope: 'buffer', quick_select: scope_str('buffer') .. '='}

  return items

get_vars = ->
  vars = [{name, def.description, :def, quick_select: name..'='} for name, def in pairs config.definitions]
  table.sort vars, (a, b) -> a[1] < b[1]
  return vars

interact.register
  name: 'get_variable_assignment'
  description: 'Get config variable and value selected by user'
  handler: ->
    command_line = howl.app.window.command_line
    buffer = howl.app.editor.buffer

    interact.sequence {'var', 'scope', 'value'},
      var: -> interact.select
        title: 'Select Variable'
        items: get_vars!
        columns: {
          { header: 'Variable', style: 'string' }
          { header: 'Description', style: 'comment' }
        }

      scope: (state) ->
        def = state.var.selection.def
        if def.scope == 'global'
          return {selection: {'global', scope: 'global'}}

        interact.select
          title: def.name
          items: scope_items def, buffer
          columns: {
            { header: 'Scope', style: 'key' }
            { header: 'Value', style: 'string' }
            { header: '', style: 'comment' }
          }
          cancel_on_back: true

      value: (state) ->
        def = state.var.selection.def
        if def.options
          items, columns = option_completions def
          selected = interact.select
            title: def.name
            :items
            :columns
            selection: option_current_value def, items, buffer
            cancel_on_back: true

          return unless selected
          return selected if selected.back

          if type(selected.selection) == 'table'
            return selected.selection[1]
          return selected.selection
        else
          interact.read_text cancel_on_back: true

      update: (state) ->
        prompt = ''
        if state.var
          prompt ..= state.var.selection.def.name .. '@'

        if state.scope
          item = state.scope.selection
          prompt ..= scope_str item.scope, item.layer
          prompt ..= '='

        command_line.prompt = prompt

        local caption
        if state.var
          def = state.var.selection.def
          caption = StyledText def.description .. '\n', {}
          if state.scope
            caption ..= StyledText '\n', {}
            caption ..= StyledText.for_table scope_items(def, buffer), {
              { style: 'key' },
              { style: 'string' }
              { style: 'comment' }
            }

        if caption
          caption_widget = howl.ui.NotificationWidget!
          command_line\add_widget 'caption', caption_widget, 'top'
          with caption_widget
            \caption caption
            \show!
        else
          command_line\remove_widget 'caption'

      finish: (state) ->
        return unless state

        return {
          var: state.var.selection.def.name,
          scope: state.scope.selection.scope,
          layer: state.scope.selection.layer,
          value: state.value
          :buffer
        }
