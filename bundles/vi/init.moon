import signal from howl

howl.ui.Editor.define_indicator 'vi', 'bottom_left'

state = bundle_load 'state.moon'

maps = {
  command: bundle_load 'command_map.moon', state
  insert: bundle_load 'insert_map.moon', state
  visual: bundle_load 'visual_map.moon', state
}

state.init maps, 'command'

signal.connect 'editor-focused', (args) -> state.change_mode args.editor, state.mode
signal.connect 'editor-defocused', (args) -> args.editor.indicator.vi.label = ''
signal.connect 'after-buffer-switch', (args) -> state.change_mode args.editor, 'command'

signal.connect 'buffer-saved', (args) ->
  if _G.editor.buffer == args.buffer
    state.change_mode _G.editor, 'command'

info = {
  name: 'vi',
  author: 'Nils Nordman <nino at nordman.org>',
  description: 'VI bundle',
  license: 'MIT',
}

return :info, :maps, :state
