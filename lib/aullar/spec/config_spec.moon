-- Copyright 2024 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

config = require 'aullar.config'

describe 'config', ->
  local old_font_size
  before_each -> old_font_size = config.view_font_size
  after_each -> config.view_font_size = old_font_size

  it 'allows direct indexing of values', ->
    font_size = config.view_font_size
    assert 'number', type(font_size)

  it 'allows direct setting of values', ->
    config.view_font_size = 123
    assert.equals 123, config.view_font_size

  it 'raises an error when trying to set a value with an incorrect type', ->
    assert.has_error ->
      config.view_font_size = 'blargh!'

  it 'allows unsetting a value by assigning nil', ->
    assert.not_has_error ->
      config.view_font_size = nil

  describe 'notifications', ->
    local listener

    before_each ->
      listener = spy.new -> nil

    after_each ->
      config.remove_listener listener

    it 'listeners are notified upon notification changes', ->
      config.add_listener listener
      old_font_size = config.view_font_size
      config.view_font_size = 321
      assert.spy(listener).was_called_with 'view_font_size', 321, old_font_size

    it 'notifies listeners with the new value in effect after the change', ->
      config.view_font_size = 111
      config.add_listener listener
      default_value = config.definition_for('view_font_size').default
      assert.is_not_nil default_value
      config.view_font_size = nil
      assert.spy(listener).was_called_with 'view_font_size', default_value, 111

    it 'listeners are not notified when the effective value is the same', ->
      config.view_font_size = 222
      config.add_listener listener
      config.view_font_size = config.view_font_size
      assert.spy(listener).was_not_called!

      default_value = config.definition_for('view_font_size').default
      config.view_font_size = default_value
      assert.spy(listener).was_called!
      config.view_font_size = nil
      assert.spy(listener).was_called(1)

    it 'does not notify removed listeners', ->
      config.add_listener listener
      config.remove_listener listener
      config.view_font_size = 123
      assert.spy(listener).was_not_called!

  describe 'local proxies', ->
    local proxy

    before_each -> proxy = config.local_proxy!

    it 'does not anchor local proxies', ->
      holder = setmetatable {config.local_proxy!}, __mode: 'v'
      collectgarbage!
      assert.is_nil holder[1]

    it 'returns the globally set value when no local value exists', ->
      config.view_font_size = 22
      assert.equals 22, proxy.view_font_size

    it 'returns the locally set value when existing', ->
      proxy.view_font_size = 33
      assert.equals 33, proxy.view_font_size

    it 'setting a local value does not affect the global value', ->
      config.view_font_size = 22
      proxy.view_font_size = 33
      assert.equals 22, config.view_font_size

    describe 'local notification listeners', ->
      local listener

      before_each -> listener = spy.new -> nil

      it 'local listeners are notified upon local notification changes', ->
        proxy\add_listener listener
        old_font_size = proxy.view_font_size
        proxy.view_font_size = 321
        assert.spy(listener).was_called_with 'view_font_size', 321, old_font_size

      it 'notifies listeners with the new value in effect after the change', ->
        config.view_font_size = 111
        proxy.view_font_size = 222
        proxy\add_listener listener
        proxy.view_font_size = nil
        assert.spy(listener).was_called_with 'view_font_size', 111, 222

      it 'does not notify removed listeners', ->
        proxy\add_listener listener
        proxy\remove_listener listener
        proxy.view_font_size = 123
        assert.spy(listener).was_not_called!

      describe 'when a local value is not set', ->
        it 'local listeners are notified upon global notification changes', ->
          proxy\add_listener listener
          old_font_size = config.view_font_size
          config.view_font_size = 123
          assert.spy(listener).was_called_with 'view_font_size', 123, old_font_size

        it 'notifications are not sent for a detached proxy', ->
          proxy\add_listener listener
          proxy\detach!
          config.view_font_size = 123
          assert.spy(listener).was_not_called!

      describe 'when a local value is set', ->
        it 'local listeners are not notified upon global notification changes', ->
          proxy.view_font_size = 44
          proxy\add_listener listener
          config.view_font_size = 123
          assert.spy(listener).was_not_called!
