import signal from lunar

lunar.ui.Editor.define_indicator 'vi', 'bottom_left'

state = bundle_load 'state.moon'

maps = {
  command: bundle_load 'command_map.moon', state
  insert: bundle_load 'insert_map.moon', state
  visual: bundle_load 'visual_map.moon', state
}

state.init maps, 'command'

signal.connect 'editor-focused', (editor) -> state.change_mode editor, state.mode
signal.connect 'editor-defocused', (editor) -> editor.indicator.vi.label = ''
signal.connect 'after-buffer-switch', (editor) -> state.change_mode editor, 'command'

signal.connect 'buffer-saved', (buffer) ->
  if _G.editor.buffer == buffer
    state.change_mode _G.editor, 'command'

info = {
  name: 'vi',
  author: 'Nils Nordman <nino at nordman.org>',
  description: 'VI bundle',
  license: 'MIT',
}

return :info, :maps, :state
