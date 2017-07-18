-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import app, interact from howl
import Window from howl.ui

require 'howl.interactions.search'
require 'howl.interactions.selection_list'

describe 'search', ->
  local command_line, searcher

  before_each ->
    app.window = Window!
    app.window\realize!
    command_line = app.window.command_line

    searcher = {}
    app.editor = :searcher

  it "registers interactions", ->
    assert.not_nil interact.forward_search
    assert.not_nil interact.backward_search
    assert.not_nil interact.forward_search_word
    assert.not_nil interact.backward_search_word

  describe 'interact.forward_search', ->
    it 'searches forward for typed text', ->
      searcher.forward_to = spy.new -> true
      within_activity interact.forward_search, ->
        command_line\write 'tw'
      assert.spy(searcher.forward_to).was_called_with searcher, 'tw', 'plain'

  describe 'interact.forward_search_word', ->
    it 'searches forward for typed word', ->
      searcher.forward_to = spy.new -> true
      within_activity interact.forward_search_word, ->
        command_line\write 'tw'
      assert.spy(searcher.forward_to).was_called_with searcher, 'tw', 'word'
