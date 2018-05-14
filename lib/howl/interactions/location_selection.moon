-- Copyright 2012-2017 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

{:app, :interact} = howl
{:Preview} = howl.interactions.util
{:highlight} = howl.ui

add_highlight = (type, buffer, line, opts = {}) ->
  start_pos, end_pos = buffer\resolve_span opts, line.nr
  highlight.apply type, buffer, start_pos, end_pos - start_pos

get_file = (item) ->
  return item.file if item.file
  unless item.directory
    error "Location item need either .file or .directory and .path"
  item.directory\join(item.path)

interact.register
  name: 'select_location'
  description: 'Selection list for locations - a location consists of a file (or buffer) and line number'
  handler: (opts) ->
    opts = moon.copy opts
    editor = opts.editor or app.editor
    preview = (howl.config.preview_files or opts.force_preview) and Preview!
    local preview_buffer

    if preview
      on_change = opts.on_change

      opts.on_change = (sel, text, items) ->
        if sel
          preview_buffer = sel.buffer or preview\get_buffer(get_file(sel), sel.line_nr)
          editor\preview preview_buffer

          highlight.remove_all 'search', preview_buffer
          highlight.remove_all 'search_secondary', preview_buffer

          if sel.line_nr
            if #preview_buffer.lines < sel.line_nr
              log.warn "Line #{sel.line_nr} not loaded in preview"
            else
              editor.line_at_center = sel.line_nr
              line = preview_buffer.lines[sel.line_nr]

              if sel.highlights and #sel.highlights > 0
                add_highlight 'search', preview_buffer, line, sel.highlights[1]

                for i = 2, #sel.highlights
                  add_highlight 'search_secondary', preview_buffer, line, sel.highlights[i]
              else
                add_highlight 'search', preview_buffer, line

        if on_change
          on_change sel, text, items

    result = interact.select opts

    if preview_buffer
      highlight.remove_all 'search', preview_buffer
      highlight.remove_all 'search_secondary', preview_buffer

    editor\cancel_preview!

    return result
