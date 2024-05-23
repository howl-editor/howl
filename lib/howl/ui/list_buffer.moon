-- Copyright 2018 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

{:app, :config, :mode} = howl
{:ActionBuffer, :BufferPopup, :highlight, :List} = howl.ui
{:Preview} = howl.interactions.util

highlight.define_default 'list_visited',
  type: highlight.STRIKE_TROUGH
  foreground: 'darkgray'
  line_width: 1
  line_type: 'solid'

ListMode = {

  default_config:
    cursor_line_highlighted: false
    line_wrapping: 'none'
    line_numbers: false
    edge_column: 0

  on_cursor_changed: (editor, cursor) =>
    list = editor.buffer.list
    list.selection = list\item_at editor.cursor.pos

  keymap: {
    editor: {
      return: (ed) ->
        ed.buffer\choose ed

      space: (ed) ->
        ed.buffer\toggle_chosen!

      p: (ed) ->
        ed.buffer\toggle_preview!

      escape: (ed) ->
        ed.buffer\cancel_preview!
     }
  }
}

class ListBuffer extends ActionBuffer
  new: (list, @opts={}) =>
    super!

    @list = List list.matcher, on_selection_change: self\_on_selection_change
    @title = opts.title or "#{#@list.items} items"
    @mode = mode.by_name 'list'
    @chosen = {}

    pos = 1
    @list.max_rows = @opts.max_rows or 1000
    @list\insert @, pos
    @list\draw!
    @modified = false
    @read_only = true

  choose: (editor) =>
    if @opts.on_submit
      sel = @list.selection
      if sel
        unless @chosen[sel]
          @mark_chosen!

        @opts.on_submit sel, @

  toggle_chosen: =>
    sel = @list.selection
    return if not sel
    if @chosen[sel]
      line = @lines[@list.selected_idx]
      highlight.remove_in_range 'list_visited', @, line.start_pos, line.end_pos
      @chosen[sel] = nil
    else
      @mark_chosen!

  mark_chosen: =>
    sel = @list.selection
    return if not sel or @chosen[sel]

    line = @lines[@list.selected_idx]
    highlight.apply 'list_visited', @, line.start_pos, line.stripped.ulen
    @chosen[sel] = true

  toggle_preview: =>
    if @_preview
      @_preview = false
    else
      @show_preview!

  show_preview: =>
    item = @list.selection
    return unless item

    @_preview = true

    if @opts.show_preview
      @opts.show_preview item, @
      return

    preview_buf = @_get_preview item
    if preview_buf
      ed = app\editor_for_buffer @
      if ed
        highlight.remove_all 'search', preview_buf
        popup = BufferPopup(preview_buf, {
          show_lines: 10,
          show_line_numbers: true,
          middle_visible_line: item.line_nr
        })
        ed\show_popup popup

        if item.highlights
          for hl in *item.highlights
            start_p, end_p = preview_buf\resolve_span hl, item.line_nr
            highlight.apply 'search', preview_buf, start_p, end_p - start_p

        return

    @cancel_preview!

  cancel_preview: =>
    @_preview = false

  _get_preview: (item) =>
    return unless config.preview_files
    file = item.file
    return unless file and file.exists
    @preview or= Preview only_previews: true
    @preview\get_buffer file, item.line_nr

  _on_selection_change: (item) =>
    @show_preview! if @_preview

howl.mode.register {
  name: 'list'
  create: -> ListMode
}

ListBuffer
