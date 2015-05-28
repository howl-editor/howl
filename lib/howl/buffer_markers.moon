-- Copyright 2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import PropertyObject from howl.aux.moon
{:copy} = moon

translate = (m, buf) ->
  m = copy m
  m.start_offset = buf\char_offset m.start_offset
  m.end_offset = buf\char_offset m.end_offset
  m

class BufferMarkers extends PropertyObject
  new: (@a_buffer) =>
    super!
    @markers = @a_buffer.markers

  @property all: {
    get: =>
      ms = @markers\for_range 1, @a_buffer.size + 1
      [translate(m, @a_buffer) for m in *ms]
  }

  add: (opts) =>
    error "Missing field 'name'", 2 unless opts.name
    opts = copy opts

    for f in *{ 'start_offset', 'end_offset' }
      v = opts[f]
      error "Missing field '#{f}'", 2 unless v
      opts[f] = @a_buffer\byte_offset v

    @markers\add opts

  at: (offset, selector) =>
    @for_range offset, offset + 1

  for_range: (start_offset, end_offset, selector) =>
    start_offset = @a_buffer\byte_offset start_offset
    end_offset = @a_buffer\byte_offset end_offset
    ms = @markers\for_range start_offset, end_offset, selector
    [translate(m, @a_buffer) for m in *ms]

  remove: (selector) =>
    @markers\remove selector

  remove_for_range: (start_offset, end_offset, selector) =>
    start_offset = @a_buffer\byte_offset start_offset
    end_offset = @a_buffer\byte_offset end_offset

    @markers\remove_for_range start_offset, end_offset, selector
