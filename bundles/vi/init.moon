import app, signal, config, command from howl
import Editor from howl.ui

state = bundle_load 'state'

maps = {
  command: bundle_load 'command_map', state
  insert: bundle_load 'insert_map', state
  visual: bundle_load 'visual_map', state
}

signal_handlers = {
  'editor-focused': (args) -> state.change_mode args.editor, state.mode if state.active
  'editor-defocused': (args) -> args.editor.indicator.vi.label = '' if state.active
  'after-buffer-switch': (args) -> state.change_mode args.editor, 'command' if state.active

  'selection-changed': ->
    if state.active and not state.executing
      editor = app.editor
      selection = editor.selection
      if state.mode == 'visual'
        state.map.__on_selection_changed editor, selection
      elseif not selection.empty and selection.anchor != selection.cursor
        state.change_mode editor, 'visual'

  'buffer-saved': (args) ->
    if state.active and app.editor.buffer == args.buffer
      state.change_mode app.editor, 'command'
    false
}

vi_commands = {
  {
    name: 'vi-on',
    description: 'Switches VI mode on'
    handler: -> state.activate(app.editor) unless state.active
  }

  {
    name: 'vi-off',
    description: 'Switches VI mode off'
    handler: ->
      if state.active
        state.deactivate!

        for editor in *howl.app.editors
          with editor
            .indicator.vi.label = ''
            .cursor.style = 'line'
            .cursor.blink_interval = config.cursor_blink_interval
  }

  {
    name: 'vi-toggle',
    description: 'Toggles VI mode'
    handler: -> if state.active then command.vi_off! else command.vi_on!
  }

  {
    name: 'vi-buffer-search-forward',
    description: 'Start an interactive forward search'
    input: ->
      if howl.interact.search_jump_to direction: 'forward', type: 'plain', match_at_cursor: false
        return true
      app.editor.searcher\cancel!
    handler: -> app.editor.searcher\commit!
  }

  {
    name: 'vi-buffer-search-backward',
    description: 'Start an interactive backward search'
    input: ->
      if howl.interact.search_jump_to direction: 'backward', type: 'plain', match_at_cursor: false
        return true
      app.editor.searcher\cancel!
    handler: -> app.editor.searcher\commit!
  }
}

unload = ->
  command.vi_off!

  for name, handler in pairs signal_handlers
    signal.disconnect name, handler

  command.unregister cmd.name for cmd in *vi_commands

  Editor.unregister_indicator 'vi'

-- Hookup
Editor.register_indicator 'vi', 'bottom_left'
state.init maps, 'command'

for name, handler in pairs signal_handlers
  signal.connect name, handler

command.register cmd for cmd in *vi_commands

info = {
  author: 'The Howl Developers',
  description: 'VI bundle',
  license: 'MIT',
}

return :info, :unload, :maps, :state
