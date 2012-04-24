import Gdk from lgi
import Spy from vilu.spec
input = vilu.input

key_code = (key) -> Gdk.keyval_from_name key

event_for = (key, modifiers = {}) ->
  {
    keyval: key_code(key),
    state:
      SHIFT_MASK: modifiers.shift
      MOD1_MASK: modifiers.alt
      CONTROL_MASK: modifiers.control
  }

describe 'Input', ->

  describe 'translate_key(event)', ->

    context 'for ordinary characters', ->
      it 'returns a table with utf8-string, key name and key code string', ->
        tr = input.translate_key event_for 'A'
        assert_table_equal tr, { 'A', 'A', tostring key_code 'A' }

    context 'for control characters', ->
      it 'returns a table with lower case key name and key code string', ->
        tr = input.translate_key event_for 'Down'
        assert_table_equal tr, { 'down', tostring key_code 'Down' }

    context 'for unknown key codes', ->
      it 'returns a table with the key code string', ->
        tr = input.translate_key keyval: 0xdeadbeef, state: {}
        assert_table_equal tr, { tostring 0xdeadbeef }

    context 'with modifiers', ->
      it 'prepends a modifier string representation to all translations', ->
        tr = input.translate_key event_for 'A', shift: true, control: true, alt: true
        mods = 'ctrl+shift+alt+'
        assert_table_equal tr, { mods .. 'A', mods .. 'A', mods .. tostring key_code 'A' }

  describe 'process(buffer, event)', ->

    context 'when looking up handlers', ->

      it 'tries each translated key in order for a given keymap', ->
        buffer = keymap: Spy!, mode: {}
        input.process buffer, event_for 'A'
        assert_table_equal buffer.keymap.reads, { 'A', 'A', tostring key_code 'A' }

      it 'searches the buffer keymap -> the mode keymap -> global keymap', ->
        event = event_for 'A'
        buffer_map = Spy!
        mode_map = Spy!
        input.keymap = Spy!

        buffer =
          keymap: buffer_map
          mode:
            keymap: mode_map

        input.process buffer, event
        assert_equal #input.keymap.reads, 3
        assert_table_equal input.keymap.reads, mode_map.reads
        assert_table_equal mode_map.reads, buffer_map.reads

    context 'when invoking handlers', ->
      it 'passes the buffer as the sole argument', ->
        received = {}
        buffer =
          keymap: { k: (...) -> received = {...} }
          mode: {}
        input.process buffer, event_for 'k'
        assert_table_equal received, { buffer }

      it 'returns early with true if a handler returns true', ->
        mode_handler = Spy!
        buffer =
          keymap: { k: (...) -> true }
          mode:
            keymap:
              k: mode_handler
        input.process buffer, event_for 'k'
        assert_false mode_handler.called

      it 'returns true if a handler raises an error', ->
        buffer =
          keymap: { k: -> error 'BOOM!' }
          mode: {}
        assert_true input.process buffer, event_for 'k'

      it 'signals an error if a handler raises an error', true
