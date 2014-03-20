Atom = require 'ljglibs.gdk.atom'
Clipboard = require 'ljglibs.gtk.clipboard'

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
