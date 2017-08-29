-- Copyright 2017 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

{:File} = howl.io
{:PropertyTable} = howl.util
{:remove, :insert} = table

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

goto_crumb = (crumb) ->
  buffer = if crumb.buffer_marker then crumb.buffer_marker.buffer_holder.buffer
  app = _G.howl.app

  if buffer
    app.editor.buffer = buffer
    app.editor.cursor.pos = crumb.pos
  elseif crumb.file
    app\open_file crumb.file
    app.editor.cursor.pos = crumb.pos

crumbs_are_equal = (c1, c2) ->
  return false unless c1.pos == c2.pos
  return true if (c1.file and c2.file) and c1.file == c2.file

  c1_buffer = c1.buffer_marker and c1.buffer_marker.buffer_holder.buffer
  c2_buffer = c2.buffer_marker and c2.buffer_marker.buffer_holder.buffer

  return true if (c1_buffer and c2_buffer) and c1_buffer == c2_buffer

  return true if c1.file and c2_buffer and c1.file == c2_buffer.file
  return true if c2.file and c1_buffer and c2.file == c1_buffer.file

  false

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
    crumbs[at] = crumb

  true

new_crumb = (buffer, file, pos) ->
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

  :file, :pos, :buffer_marker

current_edit_location_crumb = ->
  editor = _G.howl.app.editor
  return nil unless editor
  new_crumb editor.buffer, editor.buffer.file, editor.cursor.pos

drop = (opts) ->
  -- clear any existing forward crumbs
  while #crumbs >= location
    clear_crumb remove(crumbs)

  crumb = if opts
    new_crumb opts.buffer, opts.file, opts.pos
  else
    current_edit_location_crumb!

  return unless crumb
  add_crumb crumb, location
  location = next_location!

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

PropertyTable {
  trail: crumbs
  location: get: -> location
  previous: get: -> crumbs[location - 1]
  next: get: -> crumbs[location + 1]
  :clear
  :go_back
  :go_forward
  :drop
}

