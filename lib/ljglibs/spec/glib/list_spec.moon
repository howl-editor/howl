ffi = require 'ffi'
GLib = require 'ljglibs.glib'

List = GLib.List

describe 'List', ->

  to_n = (v) -> tonumber ffi.cast('int', v)

  it 'constructing returns an empty (null) list', ->
    l = List!
    assert.is_true l == nil
    assert.equals 0, l.length
    assert.equals 0, #l

  context 'with an existing list', ->
    local l

    before_each -> l = List!
    after_each -> l\free!

    it 'append(e) appends <e> to the list', ->
      l = l\append 12
      assert.equals 1, l.length
      l = l\append 34
      assert.equals 2, l.length

    it 'remove(e) removes <e> from the list', ->
      l = l\append 12
      l = l\remove 12
      assert.equals 0, l.length

    it 'nth_data(n) returns the value at <n>', ->
      l = l\append 12
      l = l\append 34
      assert.equals 12, ffi.cast 'int', l\nth_data 0
      assert.equals 34, ffi.cast 'int', l\nth_data 1

    it 'ipairs(l) allows for iterating over the contents', ->
      l = l\append 12
      l = l\append 34
      res = {}
      res[#res + 1] = {i, to_n(v)} for i, v in ipairs l
      assert.same { {1, 12 }, { 2, 34 } }, res

    it '.elements contains the elements as a table', ->
      l = l\append 12
      l = l\append 34
      nums = [to_n(e) for e in *l.elements]
      assert.same { 12, 34 }, nums
