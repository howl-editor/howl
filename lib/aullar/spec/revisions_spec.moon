Revisions = require 'aullar.revisions'
Buffer = require 'aullar.buffer'

describe 'Revisions', ->
  local revisions, buffer

  before_each ->
    revisions = Revisions!
    buffer = Buffer!

  describe 'push(type, offset, text, meta)', ->
    it 'adds revisions with the correct parameters', ->
      revisions\push 'inserted', 3, 'foo'
      assert.same {
        type: 'inserted',
        offset: 3,
        text: 'foo',
        meta: {}
      }, revisions[1]

      revisions\push 'deleted', 3, 'f', foo: 1
      assert.same {
        type: 'deleted',
        offset: 3,
        text: 'f',
        meta: { foo: 1 }
      }, revisions[2]

    it 'returns the added revision', ->
      rev = revisions\push 'inserted', 3, 'foo'
      assert.same {
        type: 'inserted',
        offset: 3,
        text: 'foo',
        meta: {}
      }, rev

    describe 'adjacent edits', ->
      it 'merges subsequent inserts', ->
        revisions\push 'inserted', 2, 'foo'
        revisions\push 'inserted', 5, 'ba'
        assert.equal 1, #revisions
        assert.same {
          type: 'inserted',
          offset: 2,
          text: 'fooba',
          meta: {}
        }, revisions.last

      it 'merges preceeding deletes', ->
        -- 123456
        revisions\push 'deleted', 4, '4'
        revisions\push 'deleted', 3, '3'
        revisions\push 'deleted', 2, '2'
        assert.equal 1, #revisions
        assert.same {
          type: 'deleted',
          offset: 2,
          text: '234',
          meta: {}
        }, revisions.last

      it 'merges deletes at the same offset', ->
        -- 123456
        revisions\push 'deleted', 4, '4'
        revisions\push 'deleted', 4, '5'
        revisions\push 'deleted', 4, '6'
        assert.equal 1, #revisions
        assert.same {
          type: 'deleted',
          offset: 4,
          text: '456',
          meta: {}
        }, revisions.last

    it 'raises an error if the type is unknown', ->
      assert.raises 'foo', -> revisions\push 'foo', 3, 'bar'

  describe 'pop(buffer)', ->
    it 'undos the stored revisions, in reverse order', ->
      -- starting with '123456789'
      revisions\push 'deleted', 9, '9' -- and we've deleted '9' at 9
      revisions\push 'inserted', 4, 'xxx' -- and inserted 'xxx' at 3
      buffer.text = '123xxx45678' -- this is what it looks like
      revisions\pop buffer -- pop the insert
      assert.equal '12345678', buffer.text
      revisions\pop buffer -- pop the delete
      assert.equal '123456789', buffer.text

    it 'returns earliest undo revision', ->
      revisions\push 'deleted', 9, '9'
      buffer.text = '12345678' -- this is what it looks like
      assert.same {
        type: 'deleted',
        offset: 9,
        text: '9',
        meta: {}
      }, revisions\pop(buffer)

  describe 'forward(buffer)', ->
    it 'does nothing when there are no revisions to apply', ->
      buffer.text = '12345'
      revisions\forward buffer
      assert.equal '12345', buffer.text
      revisions\push 'deleted', 2, 'x'
      revisions\forward buffer
      assert.equal '12345', buffer.text

    describe 'with previously popped revisions available', ->
      it 'applies the last popped revision', ->
        buffer.text = '12x3'
        revisions\push 'inserted', 3, 'x'
        revisions\pop buffer
        assert.equal '123', buffer.text
        revisions\forward buffer
        assert.equal '12x3', buffer.text

  describe 'clear()', ->
    it 'removes all previous revisions', ->
      revisions\push 'deleted', 9, '9' -- and we've deleted '9' at 9
      revisions\push 'inserted', 4, 'xxx' -- and inserted 'xxx' at 3
      revisions\clear!
      assert.equal 0, #revisions

  it '# returns the number of revisions', ->
    assert.equal 0, #revisions
    revisions\push 'inserted', 3, 'foo'
    assert.equal 1, #revisions

  describe 'grouped undos', ->
    it 'start_group() groups revisions together until end_group()', ->
      -- starting with '123456789'
      revisions\push 'deleted', 9, '9'
      revisions\start_group!
      revisions\push 'inserted', 4, 'x'
      revisions\push 'inserted', 2, 'y'
      revisions\end_group!
      buffer.text = '1y23x45678' -- this is what it looks like

      -- let's pop the grouped revisions

      assert.same { -- the last pop'ed revision should be returned
        type: 'inserted',
        offset: 4,
        text: 'x',
        group: 1,
        meta: {}
      }, revisions\pop(buffer)

      assert.equal '12345678', buffer.text -- and both should be undone
      assert.equal 1, #revisions -- with one single revision left

      -- let's forward the grouped revisions
      assert.same { -- the last forwarded revision should be returned
        type: 'inserted',
        offset: 2,
        text: 'y',
        group: 1,
        meta: {}
      }, revisions\forward(buffer)

      assert.equal '1y23x45678', buffer.text -- and both should be reapplied
      assert.equal 3, #revisions -- with three revisions left again

    it 'does not merge grouped revisions into non-group revisions', ->
      revisions\push 'inserted', 3, 'f'
      revisions\start_group!
      revisions\push 'inserted', 4, 'u'
      assert.equal 2, #revisions

    it 'treats nested groups as one big group', ->
      buffer.text = '  '
      revisions\start_group!
      revisions\push 'deleted', 1, 'x'
      revisions\start_group!
      revisions\push 'deleted', 2, 'x'
      revisions\end_group!
      revisions\push 'deleted', 3, 'x'
      revisions\end_group!
      revisions\pop buffer
      assert.equal 'x x x', buffer.text

    it 'separates adjacent undo groups', ->
      buffer.text = ' '
      revisions\start_group!
      revisions\push 'deleted', 1, 'x'
      revisions\end_group!
      revisions\start_group!
      revisions\push 'deleted', 2, 'x'
      revisions\end_group!

      revisions\pop buffer
      assert.equal ' x', buffer.text

  describe 'over-arching concerns', ->
    it 'push resets the ability to forward again', ->
      buffer.text = '  '
      revisions\push 'deleted', 1, 'x'
      revisions\push 'deleted', 2, 'x'
      revisions\push 'deleted', 3, 'x'
      revisions\pop buffer
      revisions\pop buffer
      assert.equals ' x x', buffer.text
      revisions\push 'inserted', 1, 'X'
      revisions\forward buffer -- should be a no-op
      assert.equals ' x x', buffer.text
