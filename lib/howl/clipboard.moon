-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

Atom = require 'ljglibs.gdk.atom'
GtkClipboard = require 'ljglibs.gtk.clipboard'
ffi = require 'ffi'

{:config} = howl

config.define {
  name: 'clipboard_max_items',
  description: 'The maximum number of anynomous clips to keep in the clipboard',
  type_of: 'number',
  default: 50,
  scope: 'global'
}

clips = {}
registers = {}
system_clipboard = GtkClipboard.get(Atom.SELECTION_CLIPBOARD)
sync_counter = ffi.new 'uint64_t'

local Clipboard
Clipboard = {
  push: (item, opts = {}) ->
    item = { text: item } if type(item) == 'string'
    error('Missing required field "text"', 2) unless item.text
    if opts.to
      registers[opts.to] = item
    else
      table.insert clips, 1, item
      clips[config.clipboard_max_items + 1] = nil
      system_clipboard.text = item.text
      system_clipboard\set_can_store!
      sync_counter += 1

  store: ->
    system_clipboard\store!

  clear: ->
    clips = {}
    registers = {}

  synchronize: ->
    sync_id = sync_counter
    system_clipboard\request_text (_, text) ->
      if sync_id == sync_counter and text
        cur = clips[1]
        if not cur or cur.text != text
          Clipboard.push text

  current: get: ->
    clips[1]

  clips: get: -> clips
  registers: get: -> registers
}

howl.util.PropertyTable Clipboard
