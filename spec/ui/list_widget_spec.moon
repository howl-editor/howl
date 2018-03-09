-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

-- import Buffer from howl
{:List, :ListWidget} = howl.ui
-- import ListWidget from howl.ui
{:Matcher} = howl.util

describe 'ListWidget', ->
  local list, widget

  before_each ->
    list = List -> {}
    list.max_rows_visible = 100
    widget = ListWidget list
    widget\show!

  context 'when `never_shrink:` is not provided', ->
    it 'shrinks the height while matching', ->
      list.matcher = Matcher {'one', 'twö', 'three'}
      list\update!
      height = widget.height
      assert.not_nil height

      list\update 'o'
      assert.equal height / 3, widget.height

  context 'when `never_shrink: true` is provided', ->
    it 'does not shrink the height while matching', ->
      list.matcher = Matcher({'one', 'twö', 'three'})
      widget = ListWidget list, never_shrink: true
      widget\show!
      height = widget.height
      assert.not_nil height

      list\update 'o'
      assert.equal height, widget.height
