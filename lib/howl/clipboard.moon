-- Copyright 2014-2024 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

GdkDisplay = require 'ljglibs.gdk.display'
{:PropertyTable} = howl.util
ffi = require 'ffi'

{:config, :dispatch} = howl

config.define {
  name: 'clipboard_max_items',
  description: 'The maximum number of anonymous clips to keep in the clipboard',
  type_of: 'number',
  default: 50,
  scope: 'global'
}

clips = {}
registers = {}
display = GdkDisplay.get_default!
system_clipboard = display.clipboard
system_primary = display.primary_clipboard
sync_counter = ffi.new 'uint64_t'

primary = PropertyTable {
  clear: -> system_primary\set_text ''
  text:
    set: (v) =>
      system_primary\set_text v

    get: =>
      handle = dispatch.park 'primary-clipboard-get'
      system_primary\read_text_async (res) ->
        text = system_primary\read_text_finish res
        dispatch.resume handle, text

      dispatch.wait handle
}

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
      unless opts.no_sync == true
        system_clipboard\set_text item.text
      sync_counter += 1

  clear: ->
    clips = {}
    registers = {}

  synchronize: (done) ->
    sync_id = sync_counter
    system_clipboard\read_text_async (res) ->
      status, text = pcall system_clipboard\read_text_finish, res
      if status and sync_id == sync_counter and text
        cur = clips[1]
        if not cur or cur.text != text
          Clipboard.push text, no_sync: true

      done! if done


  current: get: ->
    clips[1]

  clips: get: -> clips
  registers: get: -> registers
  primary: get: -> primary
}

PropertyTable Clipboard
