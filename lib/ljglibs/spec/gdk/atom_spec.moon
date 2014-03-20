Atom = require 'ljglibs.gdk.atom'

describe 'Atom', ->
  describe 'intern(name, only_if_exists = false)', ->
    it 'returns a atom from <name>', ->
      atom = Atom.intern('CLIPBOARD')
      assert.equal 'CLIPBOARD', atom.name

  describe 'from_value(value)', ->
    it 'allows constructing atoms directly from their value', ->
      assert.equal 'CLIPBOARD', Atom.from_value(69).name

  it 'can be constructed directly passing a string', ->
    assert.equal 'CLIPBOARD', Atom('CLIPBOARD').name

  it 'pre-defines certain atoms', ->
    assert.equal 'SECONDARY', Atom.SELECTION_SECONDARY.name
    assert.equal 'CLIPBOARD', Atom.SELECTION_CLIPBOARD.name
