import signal, config, keyhandler from howl
import Editor from howl.ui

default_keymap = keyhandler.keymap

Editor.register_indicator 'vi', 'bottom_left'
state = bundle_load 'state.moon'

maps = {
  command: bundle_load 'command_map.moon', state
  insert: bundle_load 'insert_map.moon', state
  visual: bundle_load 'visual_map.moon', state
}

state.init maps, 'command'

signal_handlers = {
  'editor-focused': (args) -> state.change_mode args.editor, state.mode
  'editor-defocused': (args) -> args.editor.indicator.vi.label = ''
  'after-buffer-switch': (args) -> state.change_mode args.editor, 'command'
  'buffer-saved': (args) ->
    if _G.editor.buffer == args.buffer
      state.change_mode _G.editor, 'command'
}

for name, handler in pairs signal_handlers
  signal.connect name, handler

unload = ->
  for name, handler in pairs signal_handlers
    signal.disconnect name, handler

  Editor.unregister_indicator 'vi'
  keyhandler.keymap = default_keymap

  for editor in *howl.app.editors
    editor.cursor.style = 'line'
    editor.cursor.blink_interval = config.cursor_blink_interval

info = {
  author: 'Nils Nordman <nino at nordman.org>',
  description: 'VI bundle',
  license: 'MIT',
}

return :info, :unload, :maps, :state
