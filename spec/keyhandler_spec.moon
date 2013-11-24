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

  describe 'process(event, source, extra_keymaps, ..)', ->

    context 'when firing the key-press signal', ->

      it 'passes the event, translations, source and parameters', ->
        event = character: 'A', key_name: 'a', key_code: 65

        with_signal_handler 'key-press', nil, (handler) ->
          status, ret = pcall keyhandler.process, event, 'editor', {}, 'yowser'
          assert.spy(handler).was.called_with {
            :event
            source: 'editor'
            translations: { 'A', 'a', '65' }
            parameters: { 'yowser' }
          }

      it 'returns early with true if the handler does', ->
        buffer = keymap: Spy!
        with_signal_handler 'key-press', true, (handler) ->
          status, ret = pcall keyhandler.process, { character: 'A', key_name: 'A', key_code: 65 }, 'editor'
          assert.equal #buffer.keymap.reads, 0
          assert.spy(handler).was.called
          assert.is_true ret

      it 'continues processing keymaps if the handler returns false', ->
        buffer = keymap: A: spy.new -> true
        with_signal_handler 'key-press', true, (handler) ->
          status, ret = pcall keyhandler.process, { character: 'A', key_name: 'A', key_code: 65 }, 'editor'
          assert.spy(buffer.keymap.A).was_called

    context 'when looking up handlers', ->

      it 'tries each translated key and .on_unhandled in order for a keymap, and optional source specific map', ->
        keymap = Spy!
        keyhandler.process { character: 'A', key_name: 'a', key_code: 65 }, 'my_source', { keymap }
        assert.same { 'my_source', 'A', 'a', '65', 'on_unhandled' }, keymap.reads

      it 'prefers source specific bindings', ->
        specific_map = A: spy.new -> nil
        general_map = {
          A: spy.new -> nil
          my_source: specific_map
        }
        keyhandler.process { character: 'A', key_name: 'a', key_code: 65 }, 'my_source', { general_map }
        assert.spy(specific_map.A).was_called(1)
        assert.spy(general_map.A).was_not_called!

      it 'searches all extra keymaps and the global keymap', ->
        key_args = character: 'A', key_name: 'a', key_code: 65
        buffer_map = Spy!
        mode_map = Spy!
        keyhandler.keymap = Spy!

        keyhandler.process key_args, 'editor', { buffer_map, mode_map }
        assert.equal #keyhandler.keymap.reads, 5
        assert.same keyhandler.keymap.reads, mode_map.reads
        assert.same mode_map.reads, buffer_map.reads

      context 'when .on_unhandled is defined and keys are not found in a keymap', ->
        it 'is called with the event, source, translations and extra parameters', ->
          keymap = on_unhandled: spy.new ->
          event = character: 'A', key_name: 'a', key_code: 65
          keyhandler.process event, 'editor', {keymap}, 'hello!'
          assert.spy(keymap.on_unhandled).was.called_with(event, 'editor', { 'A', 'a', '65' }, 'hello!')

        it 'any return is used as the handler', ->
          handler = spy.new ->
          keymap = on_unhandled: -> handler
          keyhandler.process { character: 'A', key_name: 'A', key_code: 65 }, 'editor', { keymap }
          assert.spy(handler).was.called

    context 'when invoking handlers', ->
      context 'when the handler is a function', ->
        it 'passes along any extra arguments', ->
          keymap = k: spy.new ->
          keyhandler.process { character: 'k', key_code: 65 }, 'editor', { keymap }, 'reference'
          assert.spy(keymap.k).was.called_with('reference')

        it 'returns early with true unless a handler explicitly returns false', ->
          first = k: spy.new ->
          sencond = k: spy.new ->
          assert.is_true keyhandler.process { character: 'k', key_code: 65 }, 'space', { first, second }
          assert.spy(second).was.not_called

        context 'when the handler raises an error', ->
          it 'returns true', ->
            keymap = { k: -> error 'BOOM!' }
            assert.is_true keyhandler.process { character: 'k', key_code: 65 }, 'mybad', { keymap }

          it 'logs an error to the log', ->
            keymap = { k: -> error 'a to the k log' }
            keyhandler.process { character: 'k', key_code: 65 }, 'mybad', { keymap }
            assert.is_not.equal #log.entries, 0
            assert.equal log.entries[#log.entries].message, 'a to the k log'

      context 'when the handler is a string', ->
        it 'runs the command with command.run() and returns true', ->
          cmd_run = spy.on(command, 'run')
          keymap = k: 'spy'
          assert.is_true keyhandler.process { character: 'k', key_code: 65 }, 'editor', { keymap }
          command.run\revert!
          assert.spy(cmd_run).was.called_with 'spy'

      it 'returns false if no handlers are found', ->
        assert.is_false keyhandler.process { character: 'k', key_code: 65 }, 'editor'

      it 'invokes handlers in extra keymaps before the default keymap', ->
        keyhandler.keymap = k: spy.new -> nil
        extra_map = k: spy.new -> nil
        keyhandler.process { character: 'k', key_code: 65 }, 'editor', { extra_map }
        assert.spy(extra_map.k).was_called(1)
        assert.spy(keyhandler.keymap.k).was_not_called!

  describe 'capture(function)', ->
    it 'causes <function> to be called exclusively event, source, translations and any extra parameters', ->
      event = character: 'A', key_name: 'a', key_code: 65
      thief = spy.new -> true
      keymap = A: spy.new -> true
      keyhandler.capture thief
      keyhandler.process event, 'source', { keymap }, 'catch-me!'
      assert.spy(keymap.A).was_not.called!
      assert.spy(thief).was.called_with(event, 'source', { 'A', 'a', '65' }, 'catch-me!')

    it '<function> continues to capture events as long as it returns false', ->
      ret = false
      event = character: 'A', key_name: 'A', key_code: 65
      thief = spy.new -> return ret
      keyhandler.capture thief
      keyhandler.process event, 'editor'
      ret = nil
      keyhandler.process event, 'editor'
      keyhandler.process event, 'editor'
      assert.spy(thief).was.called(2)

  it 'cancel_capture cancels any currently set capture', ->
      thief = spy.new -> return ret
      keyhandler.capture thief
      keyhandler.cancel_capture!
      keyhandler.process { character: 'A', key_name: 'A', key_code: 65 }, 'editor'
      assert.spy(thief).was_not.called!
