-- Copyright 2016 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

{:activities, :app, :bindings, :command, :config, :inspection, :interact, :log, :signal, :timer} = howl
{:ActionBuffer, :BufferPopup, :highlight} = howl.ui
{:Process, :process_output} = howl.io
{:pcall} = _G
{:sort} = table
append = table.insert

local popup, last_display_position

unavailable_warnings = {}

update_inspections_display = (editor) ->
  text = ''
  count = #editor.buffer.markers\find(name: 'inspection')
  if count > 0
    keys = bindings.keystrokes_for 'cursor-goto-inspection', 'editor'
    access = #keys > 0 and keys[1] or 'cursor-goto-inspection'
    text = "(#{count} inspection#{count > 1 and 's' or ''} - #{access} to view)"

  editor.indicator.inspections.text = text

resolve_inspector = (name, inspector, buffer) ->
  if inspector.is_available
    available, msg = inspector.is_available(buffer)
    unless available
      unless unavailable_warnings[name]
        log.warning "Inspector '#{name}' unavailable: #{msg}"
        unavailable_warnings[name] = true

      return nil

  return inspector unless inspector.cmd\find '<file>', 1, true
  return nil if not buffer.file or buffer.modified
  copy = {k,v for k, v in pairs inspector}
  copy.cmd = copy.cmd\gsub '<file>', buffer.file.path
  copy.write_stdin = false
  copy

load_inspectors = (buffer, scope = 'idle') ->
  to_load = if scope == 'all'
    {'inspectors_on_idle', 'inspectors_on_save'}
  else
    {"inspectors_on_#{scope}"}

  inspectors = {}

  for variable in *to_load
    for inspector in *buffer.config[variable]
      conf = inspection[inspector]
      if conf
        instance = conf.factory buffer
        unless callable(instance)
          if type(instance) == 'string'
            instance = resolve_inspector inspector, {cmd: instance}, buffer
          elseif type(instance) == 'table'
            unless instance.cmd
              error "Missing cmd key for inspector returned for '#{inspector}'"
            instance = resolve_inspector inspector, instance, buffer

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
      search: c.search,
      start_col: c.start_col,
      end_col: c.end_col,
      byte_start_col: c.byte_start_col,
      byte_end_col: c.byte_end_col,
    }

get_line_segment = (line, criticism) ->
  start_col = criticism.start_col
  end_col = criticism.end_col
  line_text = nil

  if not start_col and criticism.byte_start_col
    line_text or= line.text
    start_col = line_text\char_offset criticism.byte_start_col

  if not end_col and criticism.byte_end_col
    line_text or= line.text
    end_col = line_text\char_offset criticism.byte_end_col

  if not (start_col and end_col) and criticism.search
    p = r"\\b#{r.escape(criticism.search)}\\b"
    line_text or= line.text
    s, e = line_text\ufind p, start_col or 1
    if s
      unless line\ufind p, s + 1
        start_col = s
        end_col = e + 1

  if not start_col and not line.is_empty
    start_col = 1 + line.indentation

  -- check spec coverage end_pos
  start_pos = start_col and line.start_pos + start_col - 1 or line.start_pos
  end_pos = end_col and line.start_pos + end_col - 1 or line.end_pos
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

  if #ms > 0
    markers\add ms

  return #ms

parse_errors = (out, inspector) ->
  if inspector.parse
    return inspector.parse out

  inspections = {}

  for loc in *process_output.parse(out)
    complaint = {
      line: loc.line_nr,
      message: loc.message,
    }
    if loc.tokens
      complaint.search = loc.tokens[1]

    complaint.type = inspector.type or loc.message\umatch(r'^(warning|error)')

    append inspections, complaint

  if inspector.post_parse
    inspector.post_parse inspections

  inspections

launch_inspector_process = (opts, buffer) ->
  write_stdin = true unless opts.write_stdin == false

  p = Process {
    cmd: opts.cmd,
    read_stdout: true,
    read_stderr: true,
    write_stdin: write_stdin
    env: opts.env,
    shell: opts.shell,
    working_directory: opts.working_directory
  }

  if write_stdin
    p.stdin\write buffer.text
    p.stdin\close!

  p

inspect = (buffer, opts = {}) ->
  criticisms = {}
  processes = {}
  inspector_scope = opts.scope or 'all'

  for inspector in *load_inspectors(buffer, inspector_scope)
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
    out, err = activities.run_process {title: 'Reading inspection results'}, p.process
    buf = out
    buf ..= "\n#{err}" unless err.is_blank
    inspections = parse_errors buf, p.inspector
    merge(inspections, criticisms)

  criticisms

criticize = (buffer, criticisms, opts = {}) ->
  criticisms or= inspect buffer

  if opts.clear
    buffer.markers\remove name: 'inspection'

  mark_criticisms buffer, criticisms

update_buffer = (buffer, editor, scope) ->
  return if buffer.read_only
  return if buffer.data.is_preview
  data = buffer.data
  if data.last_inspect
    li = data.last_inspect
    if scope == 'idle' and li.ts >= buffer.last_changed
      return

  -- we mark this automatic inspection run with a serial
  update_serial = (data.inspections_update or 0) + 1
  data.inspections_update = update_serial

  criticisms = inspect buffer, :scope
  -- check serial to avoid applying out-of-date criticisms
  unless data.inspections_update == update_serial
    log.warn "Ignoring stale inspection update - slow inspection processes?"
    return

  criticize buffer, criticisms
  buffer.data.last_inspect = ts: buffer.last_changed, :scope

  editor or= app\editor_for_buffer buffer
  if editor
    update_inspections_display editor

popup_text = (inspections) ->
  items = {}

  prefix = #inspections > 1 and '- ' or ''
  for i = 1, #inspections
    append items, "#{prefix}<#{inspections[i].type}>#{inspections[i].message}</>"

  return howl.ui.markup.howl table.concat items, '\n'

show_popup = (editor, inspections, pos) ->
  popup or= BufferPopup ActionBuffer!
  buf = popup.buffer

  buf\as_one_undo ->
    buf.text = ''
    buf\append popup_text inspections

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
  if b.config.auto_inspect == 'on'
    if b.size < 1024 * 1024 * 5 -- 5 MB
      update_buffer b, editor, 'idle'

signal.connect 'buffer-modified', (args) ->
  with args.buffer
    .markers\remove name: 'inspection'

  editor = app\editor_for_buffer args.buffer
  if editor
    editor.indicator.inspections.text = ''

signal.connect 'buffer-saved', (args) ->
  b = args.buffer
  return unless b.size < 1024 * 1024 * 5 -- 5 MB
  return if b.config.auto_inspect == 'off'

  -- what to load? if config says 'save', all, otherwise save inspectors
  -- but if the idle hasn't had a chance to run we also run all
  scope = if b.config.auto_inspect == 'save_only'
    'all'
  elseif b.data.last_inspect and b.data.last_inspect.ts < b.last_changed
    'all'
  else
    'save'

  update_buffer b, nil, scope

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
  input: (opts) ->
    editor = app.editor
    buffer = editor.buffer
    inspections = buffer.markers\find(name: 'inspection')
    unless #inspections > 0
      log.info "No inspections for the current buffer"
      return nil

    items = {}

    last_lnr = 0
    for i in *inspections
      chunk = buffer\chunk i.start_offset, i.end_offset
      l = buffer.lines\at_pos i.start_offset
      append items, {
        if l.nr == last_lnr then '·' else tostring(l.nr),
        l.chunk,
        :chunk,
        popup: popup_text {{message: i.message, type: i.flair}}
      }
      last_lnr = l.nr

    return interact.select_location
      prompt: opts.prompt
      title: "Inspections in #{buffer.title}"
      editor: editor
      items: items
      selection: items[1]
      columns: {{style: 'comment'}, {}}

  handler: (res) ->
    if res
      chunk = res.chunk
      app.editor.cursor.pos = chunk.start_pos
      app.editor\highlight start_pos: chunk.start_pos, end_pos: chunk.end_pos

:inspect, :criticize
