-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import app, clipboard, interact from howl

clip_completions = (max_columns) ->
  completions = {}
  for i, clip in ipairs clipboard.clips
    text = clip.text\gsub '\n', '..↩'
    if text.ulen > max_columns
      text = text\usub(1, max_columns - 4) .. '[..]'

    table.insert completions, { tostring(i), text.stripped, :clip }

  return completions

interact.register
  name: 'select_clipboard_item'
  description: 'Selection list for clipboard items'
  handler: (opts={}) ->
    opts = moon.copy opts

    items = clip_completions app.window.command_line.width_cols - 9

    if #items == 0
      log.info '(Clipboard is empty)'
      return

    with opts
      .title or= 'Clipboard items'
      .items = items
      .columns = {
        { header: 'Position', style: 'number' },
        { header: 'Content', style: 'string' }
      }

    selected = interact.select opts

    if selected
      return selected.selection.clip
