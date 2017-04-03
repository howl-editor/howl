Atom = require 'ljglibs.gdk.atom'
Clipboard = require 'ljglibs.gtk.clipboard'
TargetEntry = require 'ljglibs.gtk.target_entry'

describe 'Clipboard', ->
  describe 'get(atom)', ->
    it 'returns the clipboard corresponding to <atom>', ->
      cb = Clipboard.get Atom('CLIPBOARD')
      assert.is_not_nil cb

  describe 'manipulation and access', ->
    it 'allows setting and retrieving content', ->
      cb = Clipboard.get Atom.SELECTION_CLIPBOARD
      cb\set_text 'hello!'
      assert.equals 'hello!', cb\wait_for_text!
      cb\clear!
      assert.is_nil cb\wait_for_text!

  describe '.text', ->
    it 'allows property access to the clipboard text', ->
      cb = Clipboard.get Atom.SELECTION_CLIPBOARD
      cb\set_text 'set!'
      assert.equals 'set!', cb.text
      cb.text = 'new'
      assert.equals 'new', cb\wait_for_text!

  describe 'set(targets, get_func, clear_func)', ->
    local cb, target

    before_each ->
      cb = Clipboard.get Atom.SELECTION_PRIMARY
      target = TargetEntry('UTF8_STRING')

    it 'invokes and returns the value of `get_func` on demand', ->
      get_func = () -> 'SPEC_TEXT'
      cb\set target, 1, get_func
      assert.equals 'SPEC_TEXT', cb.text

    it 'invokes the clear_func if the clipboard is cleared', ->
      get_func = () -> 'SPEC_TEXT'
      clear_func = spy.new ->
      cb\set target, 1, get_func, clear_func
      cb\clear!
      assert.spy(clear_func).was_called_with(cb)
      assert.is_nil cb.text
