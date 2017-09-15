-- Copyright 2017 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

{:signal} = howl
{:File} = howl.io
{:PropertyTable} = howl.util
{:remove, :insert} = table
{:max} = math

crumbs = {}
location = 1
marker_id = 0

next_location = ->
  nr = location + 1
  nr = 1 if nr >= math.huge
  nr

next_marker_id = ->
  marker_id += 1
  marker_id = 1 if marker_id >= math.huge
  marker_id

clear_crumb = (crumb) ->
  marker = crumb.buffer_marker
  return unless marker
  buf = marker.buffer_holder.buffer
  return unless buf
  buf.markers\remove name: marker.name

clear = ->
  while #crumbs > 0
    clear_crumb remove(crumbs)

  location = 1

navigable_crumb = (crumb) ->
  return true if crumb.file and crumb.file.exists
  crumb.buffer_marker and crumb.buffer_marker.buffer_holder.buffer

crumbs_are_equal = (c1, c2) ->
  return false unless c1 and c2
  return false unless c1.pos == c2.pos
  return true if (c1.file and c2.file) and c1.file == c2.file

  c1_buffer = c1.buffer_marker and c1.buffer_marker.buffer_holder.buffer
  c2_buffer = c2.buffer_marker and c2.buffer_marker.buffer_holder.buffer

  return true if (c1_buffer and c2_buffer) and c1_buffer == c2_buffer

  return true if c1.file and c2_buffer and c1.file == c2_buffer.file
  return true if c2.file and c1_buffer and c2.file == c1_buffer.file

  false

adjust_crumbs_for_closed_buffer = (buffer) ->
  lower_location_by = 0
  for i = #crumbs, 1, -1
    crumb = crumbs[i]
    if crumb.buffer_marker and crumb.buffer_marker.buffer_holder.buffer == buffer
      if crumb.file and crumb.file.exists
        crumb.buffer_marker = nil
      else
        remove crumbs, i
        lower_location_by += 1 if i <= location

  location = max 1, location - lower_location_by

adjust_location_for_inactive_buffer = (buffer) ->
  return unless location > 1

  buf_at_location = (loc) ->
    c = crumbs[loc]
    c.buffer_marker and c.buffer_marker.buffer_holder.buffer

  crumb_buf = buf_at_location location - 1

  if crumb_buf == buffer
    location = max 1, location - 2
    crumb_buf = buf_at_location location

    while location > 1 and crumb_buf == buffer
      location -= 1
      crumb_buf = buf_at_location location - 1
      break unless crumb_buf == buffer

goto_crumb = (crumb) ->
  buffer = if crumb.buffer_marker then crumb.buffer_marker.buffer_holder.buffer
  app = _G.howl.app
  local editor
  return unless app.editor

  if buffer
    editor = app\editor_for_buffer(buffer)
    if editor
      editor\grab_focus!
    else
      editor = app.editor
      editor.buffer = buffer
  elseif crumb.file
    _, editor = app\open_file crumb.file
  else
    return

  editor.cursor.pos = crumb.pos

  if crumb.line_at_top
    editor.line_at_top = crumb.line_at_top

add_crumb = (crumb, at, insert_crumb = false) ->
  prev_crumb = crumbs[at - 1]
  return false if prev_crumb and crumbs_are_equal crumb, prev_crumb

  next_crumb_pos = insert_crumb and at or at + 1
  next_crumb = crumbs[next_crumb_pos]
  return false if next_crumb and crumbs_are_equal crumb, next_crumb

  if crumb.buffer_marker
    crumb.buffer_marker.buffer_holder.buffer.markers\add {
      {
        name: crumb.buffer_marker.name,
        start_offset: crumb.pos,
        end_offset: crumb.pos
      }
    }

  if insert_crumb
    insert crumbs, at, crumb
  else
    cur_crumb = crumbs[at]
    clear_crumb cur_crumb if cur_crumb
    crumbs[at] = crumb

  true

new_crumb = (opts = {}) ->
  {:buffer, :file, :pos} = opts
  if type(file) == 'string'
    file = File(file)

  if buffer and not file
    file = buffer.file

  unless pos and (buffer or file)
    error "Must provide `pos` (was #{pos}), and either of `buffer` (was #{buffer}) and `file` (was #{file})", 3

  local buffer_marker

  if buffer
    buffer_marker = {
      buffer_holder: setmetatable {:buffer}, __mode: 'v'
      name: "breadcrumb-#{next_marker_id!}"
    }

  {
    :file,
    :pos,
    :buffer_marker,
    line_at_top: opts.line_at_top
  }

current_edit_location_crumb = ->
  editor = _G.howl.app.editor
  return nil unless editor
  new_crumb {
    buffer: editor.buffer,
    pos: editor.cursor.pos,
    line_at_top: editor.line_at_top
  }

drop = (opts) ->
  crumb = if opts
    new_crumb opts
  else
    current_edit_location_crumb!

  return unless crumb

  if add_crumb crumb, location
    location = next_location!

    -- clear any existing forward crumbs
    while #crumbs >= location
      clear_crumb remove(crumbs)

go_back = ->
  while true
    crumb = crumbs[location - 1]
    break unless crumb
    location -= 1
    if navigable_crumb crumb
      current_crumb = current_edit_location_crumb!
      add_crumb current_crumb, location + 1, true
      goto_crumb crumb
      break

go_forward = ->
  while true
    crumb = crumbs[location + 1]
    break unless crumb
    location += 1
    if navigable_crumb crumb
      current_crumb = current_edit_location_crumb!
      if add_crumb(current_crumb, location, true)
        location += 1

      goto_crumb crumb
      break

initialized = false

init = ->
  return if initialized

  clear!

  signal.connect 'buffer-closed', (params) ->
    adjust_location_for_inactive_buffer params.buffer
    adjust_crumbs_for_closed_buffer params.buffer

  initialized = true

PropertyTable {
  :init
  trail: crumbs
  location: get: -> location
  previous: get: -> crumbs[location - 1]
  next: get: -> crumbs[location + 1]
  :clear
  :go_back
  :go_forward
  :drop
}

