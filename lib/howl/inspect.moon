-- Copyright 2016 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

{:app, :bindings, :command, :inspection, :interact, :log, :signal, :timer} = howl
{:ActionBuffer, :BufferPopup, :highlight} = howl.ui
{:pcall} = _G
{:concat, :sort} = table
append = table.insert
local popup

update_inspections_display = (editor) ->
  text = ''
  count = #editor.buffer.markers\find(name: 'inspection')
  if count > 0
    keys = bindings.keystrokes_for 'cursor-goto-inspection', 'editor'
    access = #keys > 0 and keys[1] or 'cursor-goto-inspection'
    text = "(#{count} inspection#{count > 1 and 's' or ''} - #{access} to view)"

  editor.indicator.inspections.text = text

load_inspectors = (buffer) ->
  inspectors = {}

  for inspector in *buffer.config.inspectors
    conf = inspection[inspector]
    if conf
      append inspectors, conf.factory!
    else
      log.warn "Invalid inspector '#{inspector}' specified for '#{buffer.title}'"

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

show_popup = (editor, inspections, pos) ->
  popup or= BufferPopup ActionBuffer!
  buf = popup.buffer

  buf\as_one_undo ->
    buf.text = ''

    prefix = #inspections > 1 and '- ' or ''
    for i = 1, #inspections
      buf\append "#{prefix}#{inspections[i].message}", inspections[i].type
      unless i == #inspections
        buf\append "\n"

  with popup.view
    .cursor.line = 1
    .base_x = 0

  editor\show_popup popup, {
    position: pos,
    keep_alive: true,
  }

display_inspections = (editor) ->
  pos = editor.view.cursor.pos
  a_markers = editor.buffer.markers
  markers = a_markers\at pos
  if #markers == 0 and pos > 1
    markers = a_markers\at pos - 1

  markers = [{message: m.message, type: m.flair} for m in *markers when m.message]
  if #markers > 0
    show_popup editor, markers, editor.cursor.pos

on_idle = ->
  timer.on_idle 0.5, on_idle
  editor = app.editor
  -- if there's a popup open already of any sorts, don't interfere
  return if editor.popup

  b = editor.buffer
  if b.config.auto_inspect == 'idle'
    if b.size < 1024 * 1024 * 5 -- 5 MB
      update_buffer b, editor

  if editor.has_focus
    display_inspections editor

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

command.register
  name: 'cursor-goto-inspection'
  description: 'Goes to a specific inspection in the current buffer'
  input: ->
    editor = app.editor
    buffer = editor.buffer
    inspections = buffer.markers\find(name: 'inspection')
    unless #inspections > 0
      log.info "No inspections for the current buffer"
      return nil

    last_line = 0
    items = {}
    pbuf = howl.ui.ActionBuffer!
    popup = howl.ui.BufferPopup pbuf

    for i in *inspections
      l = buffer.lines\at_pos i.start_offset
      item = items[#items]
      if l.nr != last_line
        item = {
          tostring(l.nr),
          l.chunk,
          :buffer,
          line_nr: l.nr,
          inspections: {},
          spans: {},
          offset: i.start_offset
        }

      append item.inspections, {
        message: i.message,
        type: i.flair,
      }
      append item.spans, {
        start_offset: i.start_offset,
        count: i.end_offset - i.start_offset
      }
      if l.nr != last_line
        append items, item
      last_line = l.nr

    on_change = (selection) ->
      spans = selection.spans
      highlight.remove_all 'search', buffer
      highlight.remove_all 'search_secondary', buffer
      highlight.apply 'search', buffer, spans[1].start_offset, spans[1].count
      for i = 2, #spans
        span = spans[i]
        highlight.apply 'search_secondary', buffer, span.start_offset, span.count

      show_popup editor, selection.inspections, selection.offset

    return interact.select_location
      title: "Inspections in #{buffer.title}"
      editor: editor
      items: items,
      force_preview: true
      selection: items[1]
      :on_change

  handler: (res) ->
    app.editor.cursor.pos = res.selection.offset

:inspect, :criticize
