--- Copyright 2012-2017 The Howl Developers
--- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import config, interact, Project from howl
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

scope_str = (scope_name, layer=nil) ->
  scope_name ..= "[#{layer}]" if layer
  return scope_name

scope_item = (def, scope_name, target, description='', layer=nil) ->
  if layer
    target = target.for_layer layer
  to_s = def.tostring or tostring
  {
    scope_str(scope_name, layer), to_s(target[def.name]), description,
    :scope_name, :layer, :target,
    quick_select: scope_str(scope_name, layer) .. '='
  }

scope_items = (def, buffer) ->
  mode_layer = buffer and buffer.mode.config_layer
  mode_name = mode_layer and buffer.mode.name
  items = {}
  append items, scope_item(def, 'global', config)

  return items if def.scope == 'global' or not buffer

  append items, scope_item(
    def, 'global', config, "For all buffers with mode #{mode_name}", mode_layer)

  if buffer.file
    project = Project.for_file buffer.file
    if project
      append items, scope_item(
        def, 'project', project.config,
        "For all files under #{project.root.basename}")

      append items, scope_item(
        def, 'project', project.config,
        "For all files under #{project.root.basename} with mode #{mode_name}", mode_layer)

  append items, scope_item(
    def, 'buffer', buffer.config,
    "For #{buffer.title} only")

  return items

get_vars = ->
  vars = [{name, def.description, :def, quick_select: {name..'=', name..'@'}} for name, def in pairs config.definitions]
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

      scope: (state, from_state) ->
        def = state.var.selection.def
        if def.scope == 'global'
          if from_state == 'value'
            return { back: true }
          else
            return { selection: { 'global', scope_name: 'global', target: config } }

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
        title = "#{def.name} for #{state.scope.selection.scope_name}"
        if def.options
          items, columns = option_completions def
          selected = interact.select
            :title
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
          interact.read_text
            :title
            cancel_on_back: true

      update: (state) ->
        prompt = ''
        if state.var
          prompt ..= state.var.selection.def.name .. '@'

        if state.scope
          item = state.scope.selection
          prompt ..= scope_str item.scope_name, item.layer
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
          target: state.scope.selection.target,
          var: state.var.selection.def.name,
          value: state.value
          scope_name: state.scope.selection.scope_name,
          layer: state.scope.selection.layer,
          :buffer
        }
