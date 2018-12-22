-- Copyright 2017 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

{:signal, :config, :sys, :timer} = howl
{:File} = howl.io
{:PropertyTable} = howl.util
{:remove, :insert} = table
{:abs, :min, :max} = math

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
  buf = marker.buffer
  return unless buf
  buf.markers\remove name: marker.name

clear = ->
  while #crumbs > 0
    clear_crumb remove(crumbs)

  location = 1

crumb_pos = (crumb) ->
  marker = crumb.buffer_marker
  buffer = marker and marker.buffer
  if buffer
    markers = buffer.markers\find(name: marker.name)
    if #markers > 0
      return markers[1].start_offset

  crumb.pos

navigable_crumb = (crumb) ->
  return true if crumb.file and crumb.file.exists
  crumb.buffer_marker and crumb.buffer_marker.buffer

crumbs_are_near = (c1, c2, distance = config.breadcrumb_tolerance) ->
  return false unless c1 and c2
  return false unless abs(c1.pos - c2.pos) <= distance
  return true if (c1.file and c2.file) and c1.file == c2.file

  c1_buffer = c1.buffer_marker and c1.buffer_marker.buffer
  c2_buffer = c2.buffer_marker and c2.buffer_marker.buffer

  return true if (c1_buffer and c2_buffer) and c1_buffer == c2_buffer

  return true if c1.file and c2_buffer and c1.file == c2_buffer.file
  return true if c2.file and c1_buffer and c2.file == c1_buffer.file

  false

adjust_crumbs_for_closed_buffer = (buffer) ->
  lower_location_by = 0
  for i = #crumbs, 1, -1
    crumb = crumbs[i]
    if crumb.buffer_marker and crumb.buffer_marker.buffer == buffer
      if crumb.file and crumb.file.exists
        crumb.buffer_marker = nil
      else
        remove crumbs, i
        lower_location_by += 1 if i <= location

  location = max 1, location - lower_location_by

-- cleans up the crumbs trail, removing duplicates, loops, etc
-- for performance reasons we stop as soon as we can, meaning the tail
-- will be clean, but necessarily the entire trail
clean_crumbs_tail = ->
  remove_at = (i) ->
    clear_crumb crumbs[i]
    remove crumbs, i
    location -= 1 if i < location

  i = #crumbs
  local next, second, third
  while i > 0 and #crumbs > 0 and i >= location - 4
    cur_crumb = crumbs[i]
    cur_crumb.pos = crumb_pos cur_crumb

    -- 1: dup entries
    if crumbs_are_near cur_crumb, next
      remove_at i
    -- 2: loop cycles (1, 3, 1, 3)
    elseif crumbs_are_near(cur_crumb, second) and crumbs_are_near(next, third)
      remove_at i
      remove_at i
    -- 3:
    elseif not navigable_crumb cur_crumb
      remove_at i
    else
      third = second
      second = next
      next = cur_crumb

    i -= 1

prune_crumbs_according_to_limit = ->
  limit = config.breadcrumb_limit
  nr_to_remove = min max(#crumbs - limit, 0), location
  for i = 1, nr_to_remove
    remove crumbs, 1

  location -= nr_to_remove

adjust_location_for_inactive_buffer = (buffer) ->
  return unless location > 1

  buf_at_location = (loc) ->
    c = crumbs[loc]
    c.buffer_marker and c.buffer_marker.buffer

  crumb_buf = buf_at_location location - 1

  if crumb_buf == buffer
    location = max 1, location - 2
    crumb_buf = buf_at_location location

    while location > 1 and crumb_buf == buffer
      location -= 1
      crumb_buf = buf_at_location location - 1
      break unless crumb_buf == buffer

goto_crumb = (crumb) ->
  marker = crumb.buffer_marker
  buffer = if marker then marker.buffer
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

  pos = crumb.pos
  editor.cursor.pos = pos

  if crumb.line_at_top
    -- we try to maintain the same scrolling offset
    editor.line_at_top = crumb.line_at_top
    -- but due to potential edits we need to ensure we're actually visible
    editor\ensure_visible pos

replace_crumb = (index, new_crumb) ->
  prev_crumb = crumbs[index]
  clear_crumb prev_crumb
  crumbs[index] = new_crumb
  if new_crumb.buffer_marker
    new_crumb.buffer_marker.buffer.markers\add {
      {
        name: new_crumb.buffer_marker.name,
        start_offset: new_crumb.pos,
        end_offset: new_crumb.pos
      }
    }

add_crumb = (crumb, at, insert_crumb = false) ->
  prev_crumb = crumbs[at - 1]
  if prev_crumb and crumbs_are_near crumb, prev_crumb
    replace_crumb at - 1, crumb
    return false

  next_crumb_pos = insert_crumb and at or at + 1
  next_crumb = crumbs[next_crumb_pos]
  if next_crumb and crumbs_are_near crumb, next_crumb
    replace_crumb next_crumb_pos, crumb
    return false

  if crumb.buffer_marker
    crumb.buffer_marker.buffer.markers\add {
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
    buffer_marker = setmetatable {
      :buffer,
      name: "breadcrumb-#{next_marker_id!}"
    }, __mode: 'v'

  {
    :file,
    :pos,
    :buffer_marker,
    line_at_top: opts.line_at_top
  }

current_edit_location_crumb = ->
  editor = _G.howl.app.editor
  return nil unless editor
  return nil unless editor.cursor
  return nil unless editor.view.has_focus
  return nil if editor.buffer.data.is_preview

  new_crumb {
    buffer: editor.buffer,
    pos: editor.cursor.pos,
    line_at_top: editor.line_at_top
  }

---- Exported -----------------------------------------------------------------
-------------------------------------------------------------------------------

drop = (opts) ->
  crumb = if opts
    new_crumb opts
  else
    current_edit_location_crumb!

  return unless crumb

  if add_crumb crumb, location
    location = next_location!
    clean_crumbs_tail!
    prune_crumbs_according_to_limit!

    -- clear any existing forward crumbs
    while #crumbs >= location
      clear_crumb remove(crumbs)

go_back = ->
  clean_crumbs_tail!
  current_crumb = current_edit_location_crumb!
  idx = 1
  crumb = crumbs[location - idx]
  while crumb and crumbs_are_near(crumb, current_crumb)
    idx += 1
    crumb = crumbs[location - idx]

  crumb or= crumbs[location - 1]

  if crumb
    location -= idx
    if current_crumb
      add_crumb current_crumb, location + idx, true

    goto_crumb crumb

go_forward = ->
  clean_crumbs_tail!
  current_crumb = current_edit_location_crumb!
  idx = 1
  crumb = crumbs[location + idx]

  while crumb and crumbs_are_near(crumb, current_crumb)
    idx += 1
    crumb = crumbs[location + idx]

  crumb or= crumbs[location + 1]

  if crumb
    location += idx
    if current_crumb
      if add_crumb(current_crumb, location, true)
        location += 1

    goto_crumb crumb

initialized = false

init = ->
  return if initialized

  clear!

  signal.connect 'buffer-closed', (params) ->
    adjust_location_for_inactive_buffer params.buffer
    adjust_crumbs_for_closed_buffer params.buffer
    clean_crumbs_tail!

  initialized = true

config.define
  name: 'breadcrumb_limit'
  description: 'The maximum number of breadcrumbs to keep'
  scope: 'global'
  type_of: 'positive-number'
  default: 200

config.define
  name: 'breadcrumb_tolerance'
  description: 'Distance in positions for which breadcrumbs are merged or skipped over'
  scope: 'global'
  type_of: 'positive-number'
  default: 10

-- track last edit with a breadcrumb
last_update = sys.time!
on_idle = ->
  editor = howl.app.editor
  return unless editor
  if editor.buffer.last_changed > last_update
    last_update = editor.buffer.last_changed
    last_edit_pos = editor.last_edit_pos
    if last_edit_pos
      drop {
        buffer: editor.buffer,
        pos: last_edit_pos,
        line_at_top: editor.line_at_top
      }

  timer.on_idle 1, on_idle

timer.on_idle 1, on_idle

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

