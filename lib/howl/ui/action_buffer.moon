-- Copyright 2012-2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

{:Buffer} = howl

class ActionBuffer extends Buffer
  new:  =>
    super {}
    @collect_revisions = false

  -- action buffers are written by code, not edited documents, so they
  -- never have unsaved changes
  @property modified:
    get: -> false
    set: ->

  -- runs f with the buffer writable, for buffers that are read-only to the user
  modify: (f) =>
    read_only = @read_only
    @read_only = false
    f!
    @read_only = read_only

  insert: (object, pos, style_name) =>
    local pos_after
    if object.styles
      pos_after = @_insert_styled_object(object, pos)
    else
      @change pos, pos, ->
        pos_after = super object, pos

        if style_name
          @style pos, pos_after - 1, style_name

    pos_after

  append: (object, style_name) =>
    start_pos = @length
    local pos_after
    if object.styles
      pos_after = @_insert_styled_object(object, @length + 1)
    else
      @change start_pos, start_pos, ->
        pos_after = super object

        if style_name
          @style start_pos + 1, @length, style_name

    pos_after

  style: (start_pos, end_pos, style_name) =>
    return if end_pos < start_pos
    start_pos, end_pos = @byte_offset(start_pos), @byte_offset(end_pos + 1)
    @_buffer.styling\set start_pos, end_pos - 1, style_name

  _insert_styled_object: (object, pos) =>
    @change pos, pos, ->
      pos_after = super\insert object.text, pos
      b_start = @byte_offset pos
      @_buffer.styling\apply b_start, object.styles
      pos_after

return ActionBuffer
