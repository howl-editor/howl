-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import clipboard, interact from howl

clip_completions = ->
  completions = {}
  for i, clip in ipairs clipboard.clips
    text = clip.text\gsub '\n', '..↩'
    table.insert completions, { tostring(i), text.stripped, :clip }

  return completions

interact.register
  name: 'select_clipboard_item'
  description: 'Selection list for clipboard items'
  handler: (opts={}) ->
    opts = moon.copy opts

    items = clip_completions!

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
      .auto_trim = true

    selected = interact.select opts

    if selected
      return selected.clip
