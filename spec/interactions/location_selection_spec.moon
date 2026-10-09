-- Copyright 2026 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

{:app, :Buffer, :interact} = howl
{:highlight} = howl.ui

require 'howl.interactions.explorer'
require 'howl.interactions.location_selection'

describe 'select_location', ->
  local buffer, editor

  before_each ->
    buffer = Buffer!
    buffer.text = 'åäö line\nnext'
    editor = app.editor
    app.editor = preview: (->), cancel_preview: (->)

  after_each ->
    app.editor = editor
    if app.window
      app.window\destroy!
      app.window = nil

  preview = (location) ->
    within_command_line (-> interact.select_location items: { location }), ->

  highlighted = ->
    positions = {}
    for pos = 1, buffer.length
      for name in *highlight.at_pos(buffer, pos)
        table.insert positions, pos if name == 'search'
    positions

  describe 'previewing a location', ->
    it 'highlights the span given by start_column and end_column', ->
      preview { 'loc', :buffer, line_nr: 1, start_column: 5, end_column: 9 }
      assert.same {5, 6, 7, 8}, highlighted!

    it 'highlights the span given by byte_start_column and byte_end_column', ->
      preview { 'loc', :buffer, line_nr: 1, byte_start_column: 8, byte_end_column: 12 }
      assert.same {5, 6, 7, 8}, highlighted!

    it 'highlights one character when only the start is given', ->
      preview { 'loc', :buffer, line_nr: 1, start_column: 5 }
      assert.same {5}, highlighted!
