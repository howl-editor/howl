-- Copyright 2026 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

{:app, :bundle, :interact} = howl

require 'howl.interactions.explorer'
require 'howl.interactions.select'
require 'howl.interactions.text_entry'

enter_event = {
  key_code: 65293
  key_name: 'return'
  character: '\r'
  alt: false
  control: false
  meta: false
  shift: false
  super: false
}

describe 'read_nrepl_port', ->
  local editor

  setup ->
    bundle.load_by_name 'clojure'

  before_each ->
    editor = app.editor
    app.editor = buffer: {}

  after_each ->
    app.editor = editor
    if app.window
      app.window\destroy!
      app.window = nil

  read_port = (opts, f) ->
    local port
    within_command_line (-> port = interact.read_nrepl_port opts), f
    port

  it 'returns the port entered', ->
    port = read_port {}, (command_line) ->
      command_line\write '7888'
      command_line\handle_keypress enter_event
    assert.equals 7888, port

  it 'starts from the text given', ->
    port = read_port text: '1234', (command_line) ->
      assert.equals '1234', command_line.text
      command_line\handle_keypress enter_event
    assert.equals 1234, port

  it 'returns nil for text that is not a number', ->
    port = read_port {}, (command_line) ->
      command_line\write 'x'
      command_line\handle_keypress enter_event
    assert.is_nil port
