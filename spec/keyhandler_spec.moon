import keyhandler, signal, command from howl

describe 'keyhandler', ->

  describe 'translate_key(event)', ->

    context 'for ordinary characters', ->
      it 'returns a table with the character, key name and key code string', ->
        tr = keyhandler.translate_key character: 'A', key_name: 'a', key_code: 65
        assert.same tr, { 'A', 'a', '65' }

      it 'skips the translation for key name if it is the same as for character', ->
        tr = keyhandler.translate_key character: 'a', key_name: 'a', key_code: 65
        assert.same tr, { 'a', '65' }

    context 'when character is missing', ->
      it 'returns a table with key name and key code string', ->
        tr = keyhandler.translate_key key_name: 'down', key_code: 123
        assert.same tr, { 'down', '123' }

    context 'when only the code is available', ->
      it 'returns a table with the key code string', ->
        tr = keyhandler.translate_key key_code: 123
        assert.same tr, { '123' }

    context 'with modifiers', ->
      it 'prepends a modifier string representation to all translations for ctrl and alt', ->
        tr = keyhandler.translate_key
          character: 'A', key_name: 'a', key_code: 123,
          control: true, alt: true
        mods = 'ctrl_alt_'
        assert.same tr, { mods .. 'A', mods .. 'a', mods .. '123' }

      it 'emits the shift modifier if the character is known', ->
        tr = keyhandler.translate_key
          character: 'A', key_name: 'a', key_code: 123,
          control: true, shift: true
        assert.same tr, { 'ctrl_A', 'ctrl_shift_a', 'ctrl_shift_123' }

    it 'adds special case translations for certain common keys', ->
      for_keynames = {
        kp_up: 'up'
        kp_down: 'down'
        kp_left: 'left'
        kp_right: 'right'
        kp_page_up: 'page_up'
        kp_page_down: 'page_down'
        iso_left_tab: 'tab' -- shifts are automatically prepended
        return: 'enter'
      }

      for name, alternative in pairs for_keynames
        translations = keyhandler.translate_key key_code: 123, key_name: name
        assert.includes translations, alternative

  describe 'process(editor, buffer, event)', ->
    context 'when firing the key-press signal', ->
      it 'passes the event, translations and editor', ->
        event = character: 'A', key_name: 'a', key_code: 65
        editor = buffer: keymap: {}
        signal_handler = spy.new -> true
        signal.connect 'key-press', signal_handler

        status, ret = pcall keyhandler.process editor, event
        signal.disconnect 'key-press', signal_handler
        assert.spy(signal_handler).was.called_with :event, :editor, translations: { 'A', 'a', '65' }

      it 'returns early with true if the handler does', ->
        buffer = keymap: Spy!
        signal_handler = Spy with_return: true
        signal.connect 'key-press', signal_handler

        status, ret = pcall keyhandler.process, :buffer, { character: 'A', key_name: 'A', key_code: 65 }
        signal.disconnect 'key-press', signal_handler

        assert.equal #buffer.keymap.reads, 0
        assert.is_true signal_handler.called
        assert.is_true ret

      it 'continues processing keymaps if the handler returns false', ->
        keymap_handler = Spy!
        buffer = keymap: A: keymap_handler
        signal_handler = Spy with_return: false
        signal.connect 'key-press', signal_handler

        status, ret = pcall keyhandler.process, :buffer, { character: 'A', key_name: 'A', key_code: 65 }
        signal.disconnect 'key-press', signal_handler

        assert.is_true keymap_handler.called

    context 'when looking up handlers', ->

      it 'tries each translated key, and .on_unhandled in order for a given keymap', ->
        buffer = keymap: Spy!
        keyhandler.process :buffer, { character: 'A', key_name: 'a', key_code: 65 }
        assert.same buffer.keymap.reads, { 'A', 'a', '65', 'on_unhandled' }

      it 'searches the buffer keymap -> the mode keymap -> global keymap', ->
        key_args = character: 'A', key_name: 'a', key_code: 65
        buffer_map = Spy!
        mode_map = Spy!
        keyhandler.keymap = Spy!

        buffer =
          keymap: buffer_map
          mode:
            keymap: mode_map

        keyhandler.process :buffer, key_args
        assert.equal #keyhandler.keymap.reads, 4
        assert.same keyhandler.keymap.reads, mode_map.reads
        assert.same mode_map.reads, buffer_map.reads

      context 'when .on_unhandled is defined and keys are not found in a keymap', ->
        it 'is called with the event and translations', ->
          on_unhandled = Spy!
          buffer = keymap: { :on_unhandled }
          event = character: 'A', key_name: 'a', key_code: 65
          keyhandler.process :buffer, event
          assert.same on_unhandled.called_with, { event, { 'A', 'a', '65' } }

        it 'any return is used as the handler', ->
          handler = Spy!
          buffer = keymap: { on_unhandled: -> handler }
          keyhandler.process :buffer, { character: 'A', key_name: 'A', key_code: 65 }
          assert.is_true handler.called

      it 'skips any keymaps not present', ->
        key_args = character: 'A', key_name: 'a', key_code: 65
        keyhandler.keymap = Spy!

        buffer = {}
        assert.is_true (pcall keyhandler.process, :buffer, key_args)
        assert.equal #keyhandler.keymap.reads, 4

    context 'when invoking handlers', ->
      context 'when the handler is a function', ->
        it 'passes the editor as argument', ->
          received = {}
          buffer = keymap: { k: (...) -> received = {...} }
          editor = :buffer
          keyhandler.process editor, character: 'k', key_code: 65
          assert.same received, { editor }

        it 'returns early with true unless a handler explicitly returns false', ->
          mode_handler = Spy!
          buffer =
            keymap: { k: -> nil }
            mode:
              keymap:
                k: mode_handler
          assert.is_true keyhandler.process :buffer, { character: 'k', key_code: 65 }
          assert.is_false mode_handler.called

          buffer.keymap.k = -> false
          assert.is_true keyhandler.process :buffer, { character: 'k', key_code: 65 }
          assert.is_true mode_handler.called

        context 'when the handler raises an error', ->
          it 'returns true', ->
            buffer = keymap: { k: -> error 'BOOM!' }
            assert.is_true keyhandler.process :buffer, { character: 'k', key_code: 65 }

          it 'logs an error to the log', ->
            buffer = keymap: { k: -> error 'a to the k log' }
            keyhandler.process :buffer, { character: 'k', key_code: 65 }
            assert.is_not.equal #log.entries, 0
            assert.equal log.entries[#log.entries].message, 'a to the k log'

      context 'when the handler is a string', ->
        it 'runs the command with command.run() and returns true', ->
          cmd_run = Spy!
          orig_run = command.run
          command.run = cmd_run
          buffer = keymap: { k: 'spy' }
          status = keyhandler.process :buffer, { character: 'k', key_code: 65 }
          command.run = orig_run
          assert.is_true status
          assert.same cmd_run.called_with, { 'spy' }

      it 'returns false if no handlers are found', ->
        assert.is_false keyhandler.process buffer: {}, { character: 'k', key_code: 65 }

  describe 'capture(function)', ->
    it 'causes <function> to be called exclusively with the next key event', ->
      event = character: 'A', key_name: 'a', key_code: 65
      thief = spy.new -> true
      handler = spy.new -> true
      keyhandler.capture thief
      editor = buffer: keymap: A: handler
      keyhandler.process editor, event
      assert.spy(handler).was_not.called!
      assert.spy(thief).was.called_with(event, { 'A', 'a', '65' }, editor)

    it '<function> continues to capture events as long as it returns false', ->
      ret = false
      event = character: 'A', key_name: 'A', key_code: 65
      thief = spy.new -> return ret
      keyhandler.capture thief
      keyhandler.process buffer: {}, event
      ret = nil
      keyhandler.process buffer: {}, event
      keyhandler.process buffer: {}, event
      assert.spy(thief).was.called(2)

  it 'cancel_capture cancels any currently set capture', ->
      thief = spy.new -> return ret
      keyhandler.capture thief
      keyhandler.cancel_capture!
      keyhandler.process { buffer: {} }, { character: 'A', key_name: 'A', key_code: 65 }
      assert.spy(thief).was_not.called!
