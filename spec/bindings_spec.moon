import bindings, signal, command from howl
append = table.insert

describe 'bindings', ->

  after_each ->
    while #bindings.keymaps > 1
      bindings.pop!

  describe 'push(map, options = {})', ->
    it 'pushes <map> to the keymap stack at .keymaps', ->
      map = {}
      bindings.push map
      assert.equals map, bindings.keymaps[#bindings.keymaps]

  describe 'pop()', ->
    it 'pops the top-most keymap of the stack at .keymaps', ->
      stack_before = moon.copy bindings.keymaps
      bindings.push {}
      bindings.pop!
      assert.same stack_before, bindings.keymaps

  describe 'remove(map)', ->
    it 'removes the specified map from the keymap stack', ->
      stack = moon.copy bindings.keymaps
      m1 = {}
      m2 = {}
      bindings.push m1
      bindings.push m2
      bindings.remove m1
      append stack, m2
      assert.same stack, bindings.keymaps

  describe 'translate_key(event)', ->

    context 'for ordinary characters', ->
      it 'returns a table with the character, key name and key code string', ->
        tr = bindings.translate_key character: 'A', key_name: 'a', key_code: 65
        assert.same tr, { 'A', 'a', '65' }

      it 'skips the translation for key name if it is the same as for character', ->
        tr = bindings.translate_key character: 'a', key_name: 'a', key_code: 65
        assert.same tr, { 'a', '65' }

    context 'when character is missing', ->
      it 'returns a table with key name and key code string', ->
        tr = bindings.translate_key key_name: 'down', key_code: 123
        assert.same tr, { 'down', '123' }

    context 'when only the code is available', ->
      it 'returns a table with the key code string', ->
        tr = bindings.translate_key key_code: 123
        assert.same tr, { '123' }

    context 'with modifiers', ->
      it 'prepends a modifier string representation to all translations for ctrl and alt', ->
        tr = bindings.translate_key
          character: 'A', key_name: 'a', key_code: 123,
          control: true, alt: true
        mods = 'ctrl_alt_'
        assert.same tr, { mods .. 'A', mods .. 'a', mods .. '123' }

      it 'emits the shift modifier if the character is known', ->
        tr = bindings.translate_key
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
        translations = bindings.translate_key key_code: 123, key_name: name
        assert.includes translations, alternative

  describe 'process(event, source, extra_keymaps, ..)', ->

    context 'when firing the key-press signal', ->

      it 'passes the event, translations, source and parameters', ->
        event = character: 'A', key_name: 'a', key_code: 65

        with_signal_handler 'key-press', nil, (handler) ->
          status, ret = pcall bindings.process, event, 'editor', {}, 'yowser'
          assert.spy(handler).was.called_with {
            :event
            source: 'editor'
            translations: { 'A', 'a', '65' }
            parameters: { 'yowser' }
          }

      it 'returns early with true if the handler does', ->
        keymap = A: spy.new -> true
        with_signal_handler 'key-press', true, (handler) ->
          status, ret = pcall bindings.process, { character: 'A', key_name: 'A', key_code: 65 }, 'editor', { keymap }
          assert.spy(handler).was.called!
          assert.spy(keymap.A).was.not_called!
          assert.is_true ret

      it 'continues processing keymaps if the handler returns false', ->
        keymap = A: spy.new -> true
        with_signal_handler 'key-press', false, (handler) ->
          status, ret = pcall bindings.process, { character: 'A', key_name: 'A', key_code: 65 }, 'editor', { keymap }
          assert.spy(keymap.A).was_called!

    context 'when looking up handlers', ->

      it 'tries each translated key and .on_unhandled in order for a keymap, and optional source specific map', ->
        keymap = Spy!
        bindings.process { character: 'A', key_name: 'a', key_code: 65 }, 'my_source', { keymap }
        assert.same { 'my_source', 'A', 'a', '65', 'on_unhandled' }, keymap.reads

      it 'prefers source specific bindings', ->
        specific_map = A: spy.new -> nil
        general_map = {
          A: spy.new -> nil
          my_source: specific_map
        }
        bindings.process { character: 'A', key_name: 'a', key_code: 65 }, 'my_source', { general_map }
        assert.spy(specific_map.A).was_called(1)
        assert.spy(general_map.A).was_not_called!

      it 'searches all extra keymaps and the bindings in the stack', ->
        key_args = character: 'A', key_name: 'a', key_code: 65
        extra_map = Spy!
        stack_map = Spy!
        bindings.push stack_map
        bindings.process key_args, 'editor', { extra_map }
        assert.equal 5, #stack_map.reads
        assert.same stack_map.reads, extra_map.reads

      context 'when .on_unhandled is defined and keys are not found in a keymap', ->
        it 'is called with the event, source, translations and extra parameters', ->
          keymap = on_unhandled: spy.new ->
          event = character: 'A', key_name: 'a', key_code: 65
          bindings.process event, 'editor', {keymap}, 'hello!'
          assert.spy(keymap.on_unhandled).was.called_with(event, 'editor', { 'A', 'a', '65' }, 'hello!')

        it 'any return is used as the handler', ->
          handler = spy.new ->
          keymap = on_unhandled: -> handler
          bindings.process { character: 'A', key_name: 'A', key_code: 65 }, 'editor', { keymap }
          assert.spy(handler).was.called!

      context 'when a keymap was pushed with options.block set to true', ->
        it 'looks no further down the stack than that keymap', ->
          base = k: spy.new -> nil
          blocking = {}
          bindings.push base
          bindings.push blocking, block: true
          bindings.process { character: 'k', key_code: 65 }, 'editor'
          assert.spy(base.k).was_not_called!

      context 'when a keymap was pushed with options.pop set to true', ->

        it 'is automatically popped after the next dispatch', ->
          pop_me = k: spy.new -> nil
          bindings.push pop_me, pop: true
          bindings.process { character: 'k', key_code: 65 }, 'editor'
          assert.spy(pop_me.k).was_called!
          assert.not_includes bindings.keymaps, pop_me

        it 'is popped regardless of whether it contained a matching binding or not', ->
          pop_me = {}
          bindings.push pop_me, pop: true
          bindings.process { character: 'k', key_code: 65 }, 'editor'
          assert.not_includes bindings.keymaps, pop_me

        it 'is always blocking', ->
          base = k: spy.new -> nil
          pop_me = k: spy.new -> nil
          bindings.push base
          bindings.push pop_me, pop: true
          bindings.process { character: 'k', key_code: 65 }, 'editor'
          assert.spy(pop_me.k).was_called!
          assert.spy(base.k).was_not_called!

    context 'when invoking handlers', ->
      context 'when the handler is callable', ->
        it 'passes along any extra arguments', ->
          keymap = k: spy.new ->
          bindings.process { character: 'k', key_code: 65 }, 'editor', { keymap }, 'reference'
          assert.spy(keymap.k).was.called_with('reference')

        it 'returns early with true unless a handler explicitly returns false', ->
          first = k: spy.new ->
          second = k: spy.new ->
          assert.is_true bindings.process { character: 'k', key_code: 65 }, 'space', { first, second }
          assert.spy(second.k).was.not_called!

        context 'when the handler raises an error', ->
          it 'returns true', ->
            keymap = { k: -> error 'BOOM!' }
            assert.is_true bindings.process { character: 'k', key_code: 65 }, 'mybad', { keymap }

          it 'logs an error to the log', ->
            keymap = { k: -> error 'a to the k log' }
            bindings.process { character: 'k', key_code: 65 }, 'mybad', { keymap }
            assert.is_not.equal #log.entries, 0
            assert.equal log.entries[#log.entries].message, 'a to the k log'

      context 'when the handler is a string', ->
        it 'runs the command with command.run() and returns true', ->
          cmd_run = spy.on(command, 'run')
          keymap = k: 'spy'
          assert.is_true bindings.process { character: 'k', key_code: 65 }, 'editor', { keymap }
          command.run\revert!
          assert.spy(cmd_run).was.called_with 'spy'

      context 'when the handler is a non-callable table', ->
        it 'pushes the table as a new keymap and returns true', ->
          nr_bindings = #bindings.keymaps
          submap = {}
          keymap = k: submap
          assert.is_true bindings.process { character: 'k', key_code: 65 }, 'editor', { keymap }
          assert.equal nr_bindings + 1, #bindings.keymaps
          assert.equal submap, bindings.keymaps[#bindings.keymaps]

        it 'pushes the table with the pop option', ->
          submap = {}
          keymap = k: submap
          bindings.process { character: 'k', key_code: 65 }, 'editor', { keymap }
          bindings.process { character: 'k', key_code: 65 }, 'editor'
          assert.not_includes bindings.keymaps, submap

      it 'returns false if no handlers are found', ->
        assert.is_false bindings.process { character: 'k', key_code: 65 }, 'editor'

      it 'invokes handlers in extra keymaps before the default keymap', ->
        bindings.keymap = k: spy.new -> nil
        extra_map = k: spy.new -> nil
        bindings.process { character: 'k', key_code: 65 }, 'editor', { extra_map }
        assert.spy(extra_map.k).was_called(1)
        assert.spy(bindings.keymap.k).was_not_called!

  describe 'capture(function)', ->
    it 'causes <function> to be called exclusively with event, source, translations and any extra parameters', ->
      event = character: 'A', key_name: 'a', key_code: 65
      thief = spy.new -> true
      keymap = A: spy.new -> true
      bindings.capture thief
      bindings.process event, 'source', { keymap }, 'catch-me!'
      assert.spy(keymap.A).was_not.called!
      assert.spy(thief).was.called_with(event, 'source', { 'A', 'a', '65' }, 'catch-me!')

    it '<function> continues to capture events as long as it returns false', ->
      ret = false
      event = character: 'A', key_name: 'A', key_code: 65
      thief = spy.new -> return ret
      bindings.capture thief
      bindings.process event, 'editor'
      ret = nil
      bindings.process event, 'editor'
      bindings.process event, 'editor'
      assert.spy(thief).was.called(2)

  describe 'cancel_capture()', ->
    it 'cancels any currently set capture', ->
        thief = spy.new -> return ret
        bindings.capture thief
        bindings.cancel_capture!
        bindings.process { character: 'A', key_name: 'A', key_code: 65 }, 'editor'
        assert.spy(thief).was_not.called!
