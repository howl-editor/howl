-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

ffi = require 'ffi'
C, ffi_string, ffi_copy = ffi.C, ffi.string, ffi.copy
{:max, :min, :abs, :ceil} = math
{:define_class} = require 'aullar.util'
Styling = require 'aullar.styling'
Offsets = require 'aullar.offsets'
Markers = require 'aullar.markers'
GapBuffer = require 'aullar.gap_buffer'
Revisions = require 'aullar.revisions'
require 'ljglibs.cdefs.glib'

char_arr = ffi.typeof 'char [?]'

scan_line = (base, offset, end_offset) ->
  start_offset = offset
  was_eol = false

  byte = base[offset]
  while byte != 10 and byte != 13 and offset < end_offset
    offset += 1
    byte = base[offset]

  l_size = offset - start_offset

  if offset < end_offset -- break due to EOL
    eol_byte = byte
    was_eol = true
    offset += 1
    if eol_byte == 13 and offset < end_offset
      byte = base[offset]
      if byte == 10
        offset += 1

  offset, l_size, was_eol

LineMt = {
  __index: (line, k) ->
    if k == 'text'
      ffi_string line.ptr, line.size
}

change_sink = (start_offset, count) ->
  start_roof = start_offset + count - 1
  {
    roof: start_roof
    changes: {}
    invalidate_offset: nil
    :start_offset

    add: (type, offset, size, invalidate_offset) =>
      if offset < start_offset or (offset != start_offset and offset > @roof + 1)
        error "Out-of-range modification '#{type}' at #{offset} within change (#{start_offset} -> #{@roof})"

      @invalidate_offset or= invalidate_offset
      @invalidate_offset = min @invalidate_offset, invalidate_offset
      @changes[#@changes + 1] = :type, :offset, :size

      if type == 'deleted'
        @roof -= size
      else
        @roof += size

    add_styling_change: (start_offset, end_offset) =>
      @styling_start = min(@styling_start or start_offset, start_offset)
      @styling_end = max(@styling_end or 0, end_offset)

    add_markers_change: (start_offset, end_offset) =>
      @markers_start = min(@markers_start or start_offset, start_offset)
      @markers_end = max(@markers_end or 0, end_offset)

    can_reenter: (offset, _count) =>
      return false if offset < start_offset
      new_roof = offset + _count - 1
      return false if new_roof > max(start_roof, @roof)
      true
   }

Buffer = {
  new: (text = '') =>
    @listeners = {}
    @_style_listener = on_changed: self\_on_style_changed
    @revisions = Revisions!
    @markers = Markers {
      on_markers_added: self\_on_markers_changed
      on_markers_removed: self\_on_markers_changed
    }
    @_collect_revisions = false
    @text = text
    @_collect_revisions = true
    @read_only = false

  properties: {
    size: => tonumber @text_buffer.size
    length: => tonumber @_length
    can_undo: => #@revisions > 0
    collect_revisions: {
      get: => @_collect_revisions
      set: (v) =>
        if v != @_collect_revisions
          @_collect_revisions = v
          @revisions\clear! unless v
    }

    nr_lines: =>
      unless @_nr_lines
        @_scan_lines_to {}
        @_nr_lines = @_last_scanned_line

      @_nr_lines

    lexer: {
      get: => @_lexer
      set: (lexer) =>
        @_lexer = lexer
        @styling\invalidate_from 1
        last_viewable_line = @_get_last_viewable_line!
        if last_viewable_line > 0
          @ensure_styled_to line: last_viewable_line
    }

    text: {
      get: => @tostring!
      set: (text) =>
        @_ensure_writable!
        old_text = @text_buffer and @tostring!
        size = #text
        -- +1 on styling size to account for dangling virtual line
        if @text_buffer
          @text_buffer\set text, size
          @styling\reset size + 1
        else
          @text_buffer = GapBuffer 'char', size, initial: text
          @styling = Styling size + 1, @_style_listener

        @markers\remove!
        @_last_scanned_line = 0
        @_lines = {}
        @offsets = Offsets!
        @_length = @offsets\char_offset(@text_buffer, @text_buffer.size)
        @multibyte = @text_buffer.size != @_length

        @as_one_undo ->
          if old_text
            @_on_modification 'deleted', 1, old_text, nil, #old_text, 1

          @_on_modification 'inserted', 1, text, nil, size, 1
    }
  }

  add_listener: (listener) =>
    @listeners[#@listeners + 1] = listener

  remove_listener: (listener) =>
    @listeners = [l for l in *@listeners when l != listener]

  insert: (offset, text, size = #text) =>
    @_ensure_writable!
    return if size == 0
    error "insert: Illegal offset '#{offset}'", 2 if offset < 1 or offset > @size + 1

    invalidate_offset = min(offset, @text_buffer.gap_start + 1)
    if size > @text_buffer.gap_size -- buffer will be re-allocated
      invalidate_offset = 1

    len = C.g_utf8_strlen text, size
    @text_buffer\insert offset - 1, text, size
    @_length += len
    @_invalidate_lines_from_offset invalidate_offset
    @offsets\adjust_for_insert offset - 1, size, len
    @markers\expand offset, size
    @styling\insert offset, size, no_notify: true
    @multibyte = @text_buffer.size != @_length

    @_on_modification 'inserted', offset, text, nil, size, invalidate_offset

  delete: (offset, count) =>
    @_ensure_writable!
    return if count == 0 or offset > @size
    error "delete: Illegal offset '#{offset}'", 2 if offset < 1

    invalidate_offset = min(offset, @text_buffer.gap_start + 1)

    text = @sub offset, offset + count - 1
    len = C.g_utf8_strlen text, count
    @text_buffer\delete offset - 1, count
    @_length -= len
    @_invalidate_lines_from_offset invalidate_offset
    @offsets\adjust_for_delete offset - 1, count, len
    @markers\shrink offset, count
    @styling\delete offset, count, no_notify: true
    @multibyte = @text_buffer.size != @_length

    @_on_modification 'deleted', offset, text, nil, count, invalidate_offset

  replace: (offset, count, replacement, replacement_size = #replacement) =>
    @_ensure_writable!
    @change offset, count, ->
      @delete offset, count
      @insert offset, replacement, replacement_size

  change: (offset, count, changer) =>
    @_ensure_writable!
    if @_change_sink
      if @_change_sink\can_reenter offset, count
        changer @
      else
        error "Out of range recursive change (#{offset}, #{count}) <> (#{@_change_sink.start_offset}, #{@_change_sink.roof})"
      return

    prev_text = @sub offset, offset + count - 1
    @_change_sink = change_sink offset, count
    status, ret = pcall changer, @
    {
      :roof, :invalidate_offset, :changes,
      :styling_start, :styling_end,
      :markers_start, :markers_end
    } = @_change_sink
    new_text = @sub offset, roof
    size = max count, roof - offset, #new_text
    @_change_sink = nil

    if #changes > 0 and size > 0
      extra = :changes

      if styling_start
        styling_start = min styling_start, invalidate_offset
        styling_end = max styling_end, roof
        extra.styled = @_get_styled_notification styling_start, styling_end, true

      @_on_modification 'changed', offset, new_text, prev_text, size, invalidate_offset, extra

    elseif styling_start
      @notify('styled', @_get_styled_notification(styling_start, styling_end))

    if markers_start
      @notify 'markers_changed', start_offset: markers_start, end_offset: markers_end

    error ret unless status
    ret

  lines: (start_line = 1, end_line) =>
    i = start_line - 1
    lines = @_lines
    ->
      i += 1
      if i > @_last_scanned_line
        @_scan_lines_to line: i

      return nil if i > @_last_scanned_line
      lines[i]

  get_line: (line) =>
    @_scan_lines_to(:line) if @_last_scanned_line < line
    @_lines[line]

  get_line_at_offset: (offset) =>
    return nil if offset < 1 or offset > @size + 1
    @_scan_lines_to :offset

    min_line = 0
    max_line = @_last_scanned_line
    nr = ceil(max_line / 2)
    while nr > min_line and nr <= max_line + 1
      line = @_lines[nr]
      if offset >= line.start_offset
        return line if offset <= line.end_offset or not line.has_eol
        min_line = nr
        nr += ceil((max_line - nr) / 2)
      else
        max_line = nr
        nr -= ceil((nr - min_line) / 2)

    nil

  get_ptr: (offset, size) =>
    @text_buffer\get_ptr offset - 1, size

  sub: (start_index, end_index) =>
    return '' if start_index > @size
    end_index or= @size
    end_index = @size if end_index > @size
    size = (end_index - start_index) + 1
    return '' if size == 0
    ffi_string(@get_ptr(start_index, size), size)

  style: (offset, styling) =>
    @styling\apply offset, styling

  pair_match_forward: (offset, closing, end_offset = @size) =>
    error "`closing` must be one byte long", 2 if #closing != 1
    tb = @text_buffer
    arr = tb.array
    i = offset - 1
    offset_delta = 0
    end_offset = min @size, end_offset

    if i >= tb.gap_start
      offset_delta = tb.gap_size
      i += offset_delta
      end_offset += offset_delta

    opening = arr[i]
    opening_style = @styling\at offset
    closing = string.byte closing
    delta = 1
    i += 1 -- start at following byte

    while i < end_offset
      if opening_style == @styling\at i - offset_delta + 1
        c = arr[i]

        if c == opening
          delta += 1
        elseif c == closing
          delta -= 1
          if delta == 0
            return (i - offset_delta) + 1
      i += 1
      if i >= tb.gap_start and offset_delta == 0
        offset_delta = tb.gap_size
        i += offset_delta
        end_offset += offset_delta

    nil

  pair_match_backward: (offset, opening, end_offset = 1) =>
    error "`opening` must be one byte long", 2 if #opening != 1
    tb = @text_buffer
    arr = tb.array
    i = offset - 1
    offset_delta = 0
    end_offset -= 1

    if i >= tb.gap_start
      offset_delta = tb.gap_size
      i += offset_delta
      end_offset += offset_delta

    closing = arr[i]
    opening = string.byte opening
    opening_style = @styling\at offset
    delta = 0

    while i >= end_offset
      if opening_style == @styling\at i - offset_delta + 1
        c = arr[i]

        if c == closing
          delta += 1
        elseif c == opening
          delta -= 1
          if delta == 0
            return (i - offset_delta) + 1

      i -= 1
      if i > tb.gap_start and i < tb.gap_end
        offset_delta = 0
        i = tb.gap_start - 1
        end_offset -= tb.gap_size

    nil

  refresh_styling_at: (line_nr, to_line, opts = {}) =>
    lexer = @lexer
    at_line = @get_line line_nr
    return unless at_line and lexer

    last_styled_line = 1
    start_line = at_line
    if (@styling.last_pos_styled + 1) < start_line.start_offset
      start_line = @get_line_at_offset(@styling.last_pos_styled + 1)

    -- find the starting line to lex from
    while start_line.nr > 1
      prev_eol_style = @styling\at start_line.start_offset - 1
      break if not prev_eol_style or prev_eol_style == 'whitespace'
      start_line = @get_line(start_line.nr - 1)

    start_offset = start_line.start_offset
    at_line_eol_style = @styling\at(at_line.end_offset) or 'whitespace'

    styled = nil

    if not opts.force_full
      -- try lexing only up to this line
      text = @sub start_offset, at_line.end_offset
      @styling\clear start_offset, at_line.end_offset, no_notify: true
      @styling\apply start_offset, lexer(text), no_notify: true
      new_at_line_eol_style = @styling\at(at_line.end_offset) or 'whitespace'
      if new_at_line_eol_style == at_line_eol_style
        styled = start_line: at_line.nr, end_line: at_line.nr, invalidated: false

    unless styled
      @styling\invalidate_from at_line.start_offset, no_notify: true
      end_line = @get_line(to_line) or @get_line(@nr_lines)
      text = @sub start_offset, end_line.end_offset
      @styling\apply start_offset, lexer(text), no_notify: true
      @styling.last_pos_styled = end_line.end_offset
      styled = start_line: at_line.nr, end_line: end_line.nr, invalidated: true

    @notify('styled', styled) unless opts.no_notify
    styled

  ensure_styled_to: (opts = {}) =>
    return unless @lexer
    line_nr = opts.line

    unless line_nr
      line = @get_line_at_offset(opts.pos)
      error "Illegal `pos` specified '#{opts.pos}'", 2 unless line
      line_nr = line.nr

    to_line = @get_line min(line_nr + 20, @nr_lines)
    return unless to_line and @styling.last_pos_styled < to_line.end_offset

    from_line = @get_line_at_offset max(1, @styling.last_pos_styled)
    @refresh_styling_at from_line.nr, to_line.nr, force_full: true

  tostring: =>
    if @text_buffer.gap_size != 0
      @text_buffer\compact!
      @offsets\invalidate_from 0
      @_invalidate_lines_from_offset 0

    return ffi_string @text_buffer.array, @text_buffer.size

  char_offset: (byte_offset) =>
    byte_offset = min(@text_buffer.size + 1, max(1, byte_offset))
    return byte_offset unless @multibyte
    @offsets\char_offset(@text_buffer, byte_offset - 1) + 1

  byte_offset: (char_offset) =>
    char_offset = min(tonumber(@_length) + 1, max(1, char_offset))
    return char_offset unless @multibyte
    @offsets\byte_offset(@text_buffer, char_offset - 1) + 1

  undo: =>
    @_ensure_writable!
    revision = @revisions\pop @
    @notify('undo', revision) if revision

  redo: =>
    @_ensure_writable!
    revision = @revisions\forward @
    @notify('redo', revision) if revision

  as_one_undo: (f) =>
    unless @_collect_revisions
      return f!

    @revisions\start_group!
    status, ret = pcall f
    @revisions\end_group!
    error ret unless status

  clear_revisions: => @revisions\clear!

  get_revision_id: (snapshot=false) =>
    if snapshot and @revisions.last
      @revisions.last.dont_merge = true
    return @revisions.revision_id

  notify: (event, parameters) =>
    for listener in *@listeners
      callback = listener["on_#{event}"]
      if callback
        status, ret = pcall callback, listener, @, parameters
        print "Error emitting '#{event}': #{ret}" unless status

  _scan_lines_to: (to) =>
    tb = @text_buffer
    bytes = tb.array
    offset = 0
    base_offset = 0
    base = bytes
    nr = 0
    lines = @_lines
    size = tb.size
    bytes_size = size + tb.gap_size
    last_was_eol = false
    z_gap_start = tb.gap_start
    z_gap_end = tb.gap_end

    if @_last_scanned_line > 0
      with lines[@_last_scanned_line]
        offset = .end_offset
        nr = .nr
        last_was_eol = .has_eol

    stop_scan_at = bytes_size

    if offset >= z_gap_start
      base_offset += tb.gap_size
      offset += tb.gap_size
    else
      stop_scan_at = z_gap_start

    while (not to.line or nr < to.line) and (not to.offset or (offset - base_offset) < to.offset)
      text_ptr = base + offset
      start_p = offset - base_offset
      next_p, l_size, was_eol = scan_line base, offset, stop_scan_at

      if not was_eol and stop_scan_at != bytes_size -- at gap
        base_offset += tb.gap_size
        stop_scan_at = bytes_size
        next_p, cont_l_size, was_eol = scan_line bytes, z_gap_end, stop_scan_at
        if cont_l_size > 0 -- else gap is at end, nothing left
          gap_line = char_arr(l_size + cont_l_size)
          ffi_copy gap_line, text_ptr, l_size
          ffi_copy gap_line + l_size, bytes + z_gap_end, cont_l_size
          text_ptr = gap_line
          l_size += cont_l_size

      -- break if we're not advancing - unless the last char scanned
      -- was an end-of-line character or the absolute first line
      -- in those cases we still want the line represented
      break if next_p == offset and not (last_was_eol or nr == 0)

      nr += 1
      end_offset = max next_p - base_offset, start_p + 1

      lines[nr] = setmetatable {
        :nr
        ptr: text_ptr
        size: l_size
        full_size: end_offset - (start_p + 1) + 1
        start_offset: start_p + 1
        :end_offset
        has_eol: was_eol
      }, LineMt

      offset = next_p
      last_was_eol = was_eol

    @_last_scanned_line = max(nr, @_last_scanned_line)

  _invalidate_lines_from_offset: (offset) =>
    if offset <= 1
      @_last_scanned_line = 0
      @_lines = {}
    else
      for i = 1, @_last_scanned_line
        line = @_lines[i]
        if line.end_offset >= offset or not line.has_eol
          for j = i, @_last_scanned_line
            @_lines[j] = nil

          @_last_scanned_line = line.nr - 1
          break

  _get_last_viewable_line: =>
    last_viewable_line = 0

    for listener in *@listeners
      if listener.last_viewable_line
        last_viewable_line = max last_viewable_line, listener.last_viewable_line!

    last_viewable_line

  _get_styled_notification: (start_offset, end_offset, invalidated = false) =>
    start_line = @get_line_at_offset start_offset
    end_line = start_line
    if end_offset > start_line.end_offset and start_line.has_eol
      end_line = @get_line_at_offset end_offset

    start_line: start_line.nr, end_line: end_line.nr, :invalidated

  _on_modification: (type, offset, text, prev_text, size, invalidate_offset, extra) =>
    lines_changed = text\find('[\n\r]') != nil
    if not lines_changed and prev_text
      lines_changed = prev_text\find('[\n\r]') != nil

    @_nr_lines = nil if lines_changed

    if @_change_sink
      @_change_sink\add type, offset, size, invalidate_offset
      return

    part_of_revision = @revisions.processing
    revision = if not part_of_revision and @_collect_revisions
      @revisions\push(type, offset, text, prev_text)

    args = {
      :offset,
      :text,
      :prev_text,
      :size,
      :invalidate_offset,
      :revision,
      :part_of_revision,
      :lines_changed,
      :changes
    }
    if extra
      for k, v in pairs extra
        args[k] = v

    if @lexer
      at_line = @get_line_at_offset(offset)
      if at_line -- else at eof
        last_viewable_line = max at_line.nr, @_get_last_viewable_line!
        style_to = min(last_viewable_line + 20, @nr_lines)
        args.styled = @refresh_styling_at at_line.nr, style_to, {
          force_full: lines_changed
          no_notify: true
        }

    @notify type, args

  _on_style_changed: (_, start_offset, end_offset) =>
    if @_change_sink
      @_change_sink\add_styling_change start_offset, end_offset
      return

    @notify('styled', @_get_styled_notification(start_offset, end_offset))

  _on_markers_changed: (_, markers) =>
    start_offset = markers[1].start_offset
    end_offset = markers[#markers].end_offset

    if @_change_sink
      @_change_sink\add_markers_change start_offset, end_offset
      return

    @notify('markers_changed', :start_offset, :end_offset)

  _ensure_writable: =>
    if @read_only
      error "Attempt to modify read-only buffer", 2

}

define_class Buffer, {
  __tostring: (b) -> b\tostring!
}
