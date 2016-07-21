-- Copyright 2016 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

{:app, :config, :log, :signal, :config, :timer} = howl
{:highlight} = howl.ui
{:pcall} = _G
{:concat, :sort} = table
append = table.insert

update_inspections_display = (editor) ->
  text = ''
  count = #editor.buffer.markers\find(name: 'inspection')
  if count > 0
    text = "(#{count} inspection#{count > 1 and 's' or ''})"

  editor.indicator.inspections.text = text

load_inspectors = (buffer) ->
  inspectors = {}

  if buffer.inspectors
    for i in *buffer.inspectors
      append inspectors, i

  if buffer.mode.inspectors
    for i in *buffer.mode.inspectors
      append inspectors, i

  inspectors

merge = (found, criticisms) ->
  for c in *found
    l_nr = c.line
    criticisms[l_nr] or= {}
    append criticisms[l_nr], {
      message: c.message,
      type: c.type,
      search: c.search
    }

get_line_segment = (line, criticism) ->
  start_pos = line.start_pos
  end_pos = line.end_pos
  adjusted = false

  if criticism.search
    p = r"\\b#{r.escape(criticism.search)}\\b"
    s, e = line\ufind p, 1
    if s
      unless line\ufind p, s + 1
        end_pos = start_pos + e
        start_pos += s - 1
        adjusted = true

  if not adjusted and not line.is_empty
    start_pos += line.indentation

  start_pos, end_pos

mark_criticisms = (buffer, criticisms) ->
  {:lines, :markers} = buffer
  ms = {}
  line_nrs = [nr for nr in pairs criticisms]
  sort line_nrs

  for nr in *line_nrs
    line = lines[nr]
    list = criticisms[nr]
    continue unless line and #list > 0
    for c in *list
      start_pos, end_pos = get_line_segment line, c

      ms[#ms + 1] = {
        name: 'inspection',
        flair: c.type or 'error',
        start_offset: start_pos,
        end_offset: end_pos
        message: c.message
      }

  buffer.data.last_inspect = buffer.last_changed

  if #ms > 0
    markers\add ms

  return #ms

inspect = (buffer) ->
  criticisms = {}

  for i in *load_inspectors(buffer)
    status, ret = pcall i, buffer
    if status
      if ret
        merge ret, criticisms
    else
      log.error "inspector '#{i}' failed: #{ret}"

  criticisms

criticize = (buffer, criticisms) ->
  criticisms or= inspect buffer
  buffer.markers\remove name: 'inspection'
  mark_criticisms buffer, criticisms

update_buffer = (buffer, editor) ->
  return if buffer.read_only
  data = buffer.data
  if data.last_inspect and data.last_inspect >= buffer.last_changed
    return

  criticize buffer
  editor or= app\editor_for_buffer buffer
  if editor
    update_inspections_display editor

on_idle = ->
  b = app.editor.buffer
  return unless b.config.auto_inspect == 'idle'
  return unless b.size < 1024 * 1024 -- 1MB
  update_buffer app.editor.buffer, app.editor
  timer.on_idle 0.5, on_idle

signal.connect 'buffer-modified', (args) ->
  with args.buffer
    .markers\remove name: 'inspection'

  editor = app\editor_for_buffer args.buffer
  if editor
    editor.indicator.inspections.text = ''

signal.connect 'buffer-saved', (args) ->
  b = args.buffer
  return unless b.config.auto_inspect == 'save'
  return unless b.size < 1024 * 1024 -- 1MB
  update_buffer b

signal.connect 'after-buffer-switch', (args) ->
  update_buffer args.current_buffer, args.editor

signal.connect 'app-ready', (args) ->
  timer.on_idle 0.5, on_idle

config.define {
  name: 'auto_inspect'
  description: 'When to automatically inspect code for abberrations-'
  default: 'idle'
  options: {
    { 'manual', 'Only inspect when explicitly asked' }
    { 'idle', 'Inspect on idle' }
    { 'save', 'Inspect when saving a buffer' }
  }
}

highlight.define_default 'error',
  type: highlight.WAVY_UNDERLINE
  foreground: 'red'
  line_width: 1
  line_type: 'solid'

highlight.define_default 'warning',
  type: highlight.WAVY_UNDERLINE
  foreground: 'orange'
  line_width: 1
  line_type: 'solid'

:inspect, :criticize
