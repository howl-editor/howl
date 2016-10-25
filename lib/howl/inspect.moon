-- Copyright 2016 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

{:app, :bindings, :command, :config, :inspection, :interact, :log, :signal, :timer} = howl
{:ActionBuffer, :BufferPopup, :highlight} = howl.ui
{:Process, :process_output} = howl.io
{:pcall} = _G
{:sort} = table
append = table.insert

local popup, last_display_position

update_inspections_display = (editor) ->
  text = ''
  count = #editor.buffer.markers\find(name: 'inspection')
  if count > 0
    keys = bindings.keystrokes_for 'cursor-goto-inspection', 'editor'
    access = #keys > 0 and keys[1] or 'cursor-goto-inspection'
    text = "(#{count} inspection#{count > 1 and 's' or ''} - #{access} to view)"

  editor.indicator.inspections.text = text

resolve_inspector = (inspector, buffer) ->
  return inspector unless inspector.cmd\find '<file>', 1, true
  return nil unless buffer.file
  copy = {k,v for k, v in pairs inspector}
  copy.cmd = copy.cmd\gsub '<file>', buffer.file.path
  copy

load_inspectors = (buffer) ->
  inspectors = {}

  for inspector in *buffer.config.inspectors
    conf = inspection[inspector]
    if conf
      instance = conf.factory buffer
      if callable(instance)
        append inspectors, instance
      elseif type(instance) == 'string'
        instance = resolve_inspector {cmd: instance}, buffer
        if instance
          append inspectors, instance
      elseif type(instance) == 'table'
        unless instance.cmd
          error "Missing cmd key for inspector returned for '#{inspector}'"
        instance = resolve_inspector instance, buffer
        if instance
          append inspectors, instance

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

parse_errors = (out, inspector) ->
  if inspector.parse
    return inspector.parse out

  inspections = {}

  for loc in *process_output.parse(out)
    complaint = {
      line: loc.line,
      message: loc.message,
    }
    if loc.tokens
      complaint.search = loc.tokens[1]

    complaint.type = loc.message\umatch(r'^(warning|error)')

    append inspections, complaint

  if inspector.post_parse
    inspector.post_parse inspections

  inspections

launch_inspector_process = (opts, buffer) ->
  p = Process {
    cmd: opts.cmd,
    read_stdout: true,
    read_stderr: true,
    write_stdin: true
    env: opts.env,
    shell: opts.shell,
    working_directory: opts.working_directory
  }
  p.stdin\write buffer.text
  p.stdin\close!
  p

inspect = (buffer) ->
  criticisms = {}
  processes = {}

  for inspector in *load_inspectors(buffer)
    if callable(inspector)
      status, ret = pcall inspector, buffer
      if status
        merge(ret or {}, criticisms)
      else
        log.error "inspector '#{inspector}' failed: #{ret}"
    else
      p = launch_inspector_process inspector, buffer
      processes[#processes + 1] = { process: p, :inspector }

  -- finish off processes
  for p in *processes
    out, err = p.process\pump!
    buf = out
    buf ..= "\n#{err}" unless err.is_blank
    inspections = parse_errors buf, p.inspector
    merge(inspections, criticisms)

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

  -- we mark this automatic inspection run with a serial
  update_serial = (data.inspections_update or 0) + 1
  data.inspections_update = update_serial

  criticisms = inspect buffer
  -- check serial to avoid applying out-of-date criticisms
  unless data.inspections_update == update_serial
    log.warn "Ignoring stale inspection update - slow inspection processes?"
    return

  criticize buffer, criticisms

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

display_inspections = ->
  timer.on_idle (config.display_inspections_delay / 1000), display_inspections

  editor = app.editor
  return unless editor.has_focus

  pos = editor.view.cursor.pos

  -- if we've already displayed the message at this position, punt
  return if pos == last_display_position

  a_markers = editor.buffer.markers.markers
  markers = a_markers\at pos
  if #markers == 0 and pos > 1
    markers = a_markers\at pos - 1

  markers = [{message: m.message, type: m.flair} for m in *markers when m.message]
  if #markers > 0
    last_display_position = pos
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
  update_inspections_display args.editor

signal.connect 'preview-opened', (args) ->
  args.editor.indicator.inspections.text = ''

signal.connect 'preview-closed', (args) ->
  update_inspections_display args.editor

signal.connect 'cursor-changed', (args) ->
  last_display_position = nil

signal.connect 'editor-defocused', (args) ->
  last_display_position = nil

signal.connect 'app-ready', (args) ->
  timer.on_idle 0.5, on_idle
  timer.on_idle (config.display_inspections_delay / 1000), display_inspections

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
  name: 'buffer-inspect'
  description: 'Inspects the current buffer for abberations'
  handler: ->
    buffer = app.editor.buffer
    criticize buffer
    editor or= app\editor_for_buffer buffer
    if editor
      update_inspections_display editor

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
