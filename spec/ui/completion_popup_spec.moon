-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import Buffer from howl
import Editor, CompletionPopup from howl.ui

describe 'CompletionPopup', ->
  context 'resource management', ->
    editor = Editor Buffer!

    it 'popups are collected as they should', ->
      o = CompletionPopup editor
      list = setmetatable {o}, __mode: 'v'
      o\destroy!
      o = nil
      collectgarbage!
      assert.is_true list[1] == nil, 'Object still lives'
