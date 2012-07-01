import Spy from vilu.spec
import input, signal from vilu

describe 'Input', ->

  describe 'translate_key(event)', ->

    context 'for ordinary characters', ->
      it 'returns a table with the character, key name and key code string', ->
        tr = input.translate_key character: 'A', key_name: 'A', key_code: 65
        assert_table_equal tr, { 'A', 'A', '65' }

    context 'when character is missing', ->
      it 'returns a table with key name and key code string', ->
        tr = input.translate_key key_name: 'down', key_code: 123
        assert_table_equal tr, { 'down', '123' }

    context 'when only the code is available', ->
      it 'returns a table with the key code string', ->
        tr = input.translate_key key_code: 123
        assert_table_equal tr, { '123' }

    context 'with modifiers', ->
      it 'prepends a modifier string representation to all translations for ctrl and alt', ->
        tr = input.translate_key
          character: 'a', key_name: 'a', key_code: 123,
          control: true, alt: true
        mods = 'ctrl+alt+'
        assert_table_equal tr, { mods .. 'a', mods .. 'a', mods .. '123' }

      it 'emits the shift modifier if the character is known', ->
        tr = input.translate_key
          character: 'A', key_name: 'a', key_code: 123,
          control: true, shift: true
        assert_table_equal tr, { 'ctrl+A', 'ctrl+shift+a', 'ctrl+shift+123' }

  describe 'process(editor, buffer, event)', ->
    context 'when firing the key-press signal', ->
      it 'passes the event and translations', ->
        event = character: 'A', key_name: 'A', key_code: 65
        buffer = keymap: {}
        signal_handler = Spy!
        signal.connect 'key-press', signal_handler

        status, ret = pcall input.process :buffer, event
        signal.disconnect 'key-press', signal_handler
        assert_table_equal signal_handler.called_with, { event, { 'A', 'A', '65' } }

      it 'returns early with true if the handler does', ->
        buffer = keymap: Spy!
        signal_handler = Spy with_return: true
        signal.connect 'key-press', signal_handler

        status, ret = pcall input.process, :buffer, { character: 'A', key_name: 'A', key_code: 65 }
        signal.disconnect 'key-press', signal_handler

        assert_equal #buffer.keymap.reads, 0
        assert_true signal_handler.called
        assert_true ret

      it 'continues processing keymaps if the handler returns false', ->
        keymap_handler = Spy!
        buffer = keymap: A: keymap_handler
        signal_handler = Spy with_return: false
        signal.connect 'key-press', signal_handler

        status, ret = pcall input.process, :buffer, { character: 'A', key_name: 'A', key_code: 65 }
        signal.disconnect 'key-press', signal_handler

        assert_true keymap_handler.called

    context 'when looking up handlers', ->

      it 'tries each translated key, and .on_unhandled in order for a given keymap', ->
        buffer = keymap: Spy!
        input.process :buffer, { character: 'A', key_name: 'A', key_code: 65 }
        assert_table_equal buffer.keymap.reads, { 'A', 'A', '65', 'on_unhandled' }

      it 'searches the buffer keymap -> the mode keymap -> global keymap', ->
        key_args = character: 'A', key_name: 'A', key_code: 65
        buffer_map = Spy!
        mode_map = Spy!
        input.keymap = Spy!

        buffer =
          keymap: buffer_map
          mode:
            keymap: mode_map

        input.process :buffer, key_args
        assert_equal #input.keymap.reads, 4
        assert_table_equal input.keymap.reads, mode_map.reads
        assert_table_equal mode_map.reads, buffer_map.reads

      context 'when .on_unhandled is defined and keys are not found in a keymap', ->
        it 'is called with the event and translations', ->
          on_unhandled = Spy!
          buffer = keymap: { :on_unhandled }
          event = character: 'A', key_name: 'A', key_code: 65
          input.process :buffer, event
          assert_table_equal on_unhandled.called_with, { event, { 'A', 'A', '65' } }

        it 'any return is used as the handler', ->
          handler = Spy!
          buffer = keymap: { on_unhandled: -> handler }
          input.process :buffer, { character: 'A', key_name: 'A', key_code: 65 }
          assert_true handler.called

      it 'skips any keymaps not present', ->
        key_args = character: 'A', key_name: 'A', key_code: 65
        input.keymap = Spy!

        buffer = {}
        assert_true (pcall input.process, :buffer, key_args)
        assert_equal #input.keymap.reads, 4

    context 'when invoking handlers', ->
      it 'passes the editor as argument', ->
        received = {}
        buffer = keymap: { k: (...) -> received = {...} }
        editor = :buffer
        input.process editor, character: 'k', key_code: 65
        assert_table_equal received, { editor }

      it 'returns early with true unless a handler explicitly returns false', ->
        mode_handler = Spy!
        buffer =
          keymap: { k: -> nil }
          mode:
            keymap:
              k: mode_handler
        assert_true input.process :buffer, { character: 'k', key_code: 65 }
        assert_false mode_handler.called

        buffer.keymap.k = -> false
        assert_true input.process :buffer, { character: 'k', key_code: 65 }
        assert_true mode_handler.called

      context 'when a handler raises an error', ->
        it 'returns true', ->
          buffer = keymap: { k: -> error 'BOOM!' }
          assert_true input.process :buffer, { character: 'k', key_code: 65 }

        it 'signals an error', ->
          handler = Spy!
          signal.connect_first 'error', handler
          buffer = keymap: { k: -> error 'BOOM!' }
          input.process :buffer, { character: 'k', key_code: 65 }
          assert_true handler.called

      it 'returns false if no handlers are found', ->
        assert_false input.process buffer: {}, { character: 'k', key_code: 65 }


