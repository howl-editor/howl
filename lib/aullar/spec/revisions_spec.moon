-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

Revisions = require 'aullar.revisions'
Buffer = require 'aullar.buffer'
config = require 'aullar.config'

describe 'Revisions', ->
  local revisions, buffer

  before_each ->
    revisions = Revisions!
    buffer = Buffer!
    config.undo_limit = 30

  describe 'push(type, offset, text, meta)', ->
    it 'adds revisions with the correct parameters', ->
      revisions\push 'inserted', 3, 'foo'
      assert.same {
        type: 'inserted',
        offset: 3,
        text: 'foo',
        meta: {},
        revision_id: 1
      }, revisions.entries[1]

      revisions\push 'deleted', 3, 'f', nil, foo: 1
      assert.same {
        type: 'deleted',
        offset: 3,
        text: 'f',
        meta: { foo: 1 },
        revision_id: 2
      }, revisions.entries[2]

      revisions\push 'changed', 3, 'f', 'x'
      assert.same {
        type: 'changed',
        offset: 3,
        text: 'f',
        prev_text: 'x',
        meta: {},
        revision_id: 3
      }, revisions.entries[3]

    it 'returns the added revision', ->
      rev = revisions\push 'inserted', 3, 'foo'
      assert.same {
        type: 'inserted',
        offset: 3,
        text: 'foo',
        meta: {},
        revision_id: 1
      }, rev

    it 'keeps at most config.undo_limit revisions', ->
      config.undo_limit = 1
      revisions\push 'inserted', 3, 'foo'
      revisions\push 'inserted', 1, 'bar'
      assert.equals 1, #revisions
      assert.equals 'bar', revisions.entries[1].text

    describe 'adjacent edits', ->
      it 'merges subsequent inserts', ->
        revisions\push 'inserted', 2, 'foo'
        revisions\push 'inserted', 5, 'ba'
        assert.equal 1, #revisions
        assert.same {
          type: 'inserted',
          offset: 2,
          text: 'fooba',
          meta: {},
          revision_id: 1
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
          meta: {},
          revision_id: 1
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
          meta: {},
          revision_id: 1
        }, revisions.last

      it 'does not merge if dont_merge is set on a revision', ->
        buffer.text = 'a'
        revisions\push 'inserted', 2, 'foo'
        revisions.last.dont_merge = true
        revisions\push 'inserted', 5, 'ba'
        assert.equal 2, #revisions
        buffer.text = 'afooba'

        assert.same {
          type: 'inserted',
          offset: 5,
          text: 'ba',
          meta: {},
          revision_id: 2
        }, revisions\pop(buffer)

        assert.same {
          type: 'inserted',
          offset: 2,
          text: 'foo',
          meta: {},
          revision_id: 1
          dont_merge: true
        }, revisions.last

    it 'raises an error if the type is unknown', ->
      assert.raises 'foo', -> revisions\push 'foo', 3, 'bar'

  describe 'pop(buffer)', ->
    it 'undos the stored revisions, in reverse order', ->
      -- starting with '123456789'
      revisions\push 'deleted', 9, '9' -- and we've deleted '9' at 9
      revisions\push 'inserted', 4, 'xxx' -- and inserted 'xxx' at 3
      revisions\push 'changed', 1, 'abc', '123' -- and replaced '123' with 'abc'
      buffer.text = 'abcxxx45678' -- this is what it looks like

      revisions\pop buffer -- pop the change
      assert.equal '123xxx45678', buffer.text

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
        meta: {},
        revision_id: 1
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
      it 'handles inserts', ->
        buffer.text = '12x3'
        revisions\push 'inserted', 3, 'x'
        revisions\pop buffer
        assert.equal '123', buffer.text
        revisions\forward buffer
        assert.equal '12x3', buffer.text

      it 'handles changes', ->
        buffer.text = '12xy'
        revisions\push 'changed', 3, 'xy', '3'
        revisions\pop buffer
        assert.equal '123', buffer.text
        revisions\forward buffer
        assert.equal '12xy', buffer.text

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
        meta: {},
        revision_id: 2
      }, revisions\pop(buffer)

      assert.equal '12345678', buffer.text -- and both should be undone
      assert.equal 1, #revisions -- with one single revision left

      -- let's forward the grouped revisions
      assert.same { -- the last forwarded revision should be returned
        type: 'inserted',
        offset: 2,
        text: 'y',
        group: 1,
        meta: {},
        revision_id: 3
      }, revisions\forward(buffer)

      assert.equal '1y23x45678', buffer.text -- and both should be reapplied
      assert.equal 3, #revisions.entries -- with three revisions left again

    it 'accounts for empty groups', ->
      revisions\start_group!
      revisions\end_group!
      assert.equal 0, #revisions.entries
      assert.equal 0, #revisions

    it 'does not merge grouped revisions into non-group revisions', ->
      revisions\push 'inserted', 3, 'f'
      revisions\start_group!
      revisions\push 'inserted', 4, 'u'
      revisions\end_group!
      assert.equal 2, #revisions.entries

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

    it 'counts each group as one revision', ->
      revisions\start_group!
      revisions\push 'inserted', 3, 'x'
      revisions\push 'inserted', 1, 'y'
      revisions\end_group!

      assert.equals 1, #revisions

      revisions\start_group!
      revisions\push 'inserted', 3, 'bar'
      revisions\push 'inserted', 1, 'zed'
      revisions\end_group!

      assert.equals 2, #revisions

    it 'treats undo groups as single revisions when applying the undo limit', ->
      config.undo_limit = 1
      revisions\start_group!
      revisions\push 'inserted', 3, 'x'
      revisions\push 'inserted', 1, 'y'
      revisions\end_group!

      assert.equals 2, #revisions.entries
      assert.equals 1, #revisions

      config.undo_limit = 2
      revisions\start_group!
      revisions\push 'inserted', 3, 'bar'
      revisions\push 'inserted', 1, 'zed'
      revisions\end_group!

      assert.equals 4, #revisions.entries
      assert.equals 2, #revisions

      revisions\start_group!
      revisions\push 'inserted', 3, 'last'
      revisions\end_group!

      assert.equals 3, #revisions.entries
      assert.equals 2, #revisions
      assert.equals 'last', revisions.entries[3].text

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
