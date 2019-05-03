-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import app, interact from howl
match = require 'luassert.match'

require 'howl.interactions.search'
require 'howl.interactions.select'

describe 'search', ->
  local searcher

  before_each ->
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
      within_command_line (-> interact.forward_search {}), (command_line) ->
        command_line\write 'tw'
      assert.spy(searcher.forward_to).was_called_with match.is_ref(searcher), 'tw', 'plain'


  describe 'interact.forward_search_word', ->
    it 'searches forward for typed word', ->
      searcher.forward_to = spy.new -> true
      within_command_line (-> interact.forward_search_word {}), (command_line) ->
        command_line\write 'tw'
      assert.spy(searcher.forward_to).was_called_with match.is_ref(searcher), 'tw', 'word'
