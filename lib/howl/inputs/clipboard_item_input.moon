-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE.md)

import clipboard from howl
import Matcher from howl.util

completion_options = {
  title: 'Clipboard items',
  list: {
    headers: { 'Position', 'Content' }
    column_styles: { 'number', 'string' }
  }
}

clip_completions = (max_columns) ->
  completions = {}
  for i, clip in ipairs clipboard.clips
    text = clip.text\gsub '\n', '..↩'
    if text.ulen > max_columns
      text = text\usub(1, max_columns - 4) .. '[..]'

    completions[#completions + 1] = { tostring(i), text.stripped }

  completions

input = {
  should_complete: -> true
  close_on_cancel: -> true

  complete: (text, readline) =>
    completions = clip_completions readline.width_in_columns or 100
    if #completions == 0
      readline\notify '(Clipboard is empty..)'
      return

    matcher = Matcher completions
    return matcher(text), completion_options

  on_submit: (value) =>
    index = tonumber value
    index != nil and index >=1 and index <= #clipboard.clips

  value_for: (position) =>
    clipboard.clips[tonumber(position)]
}

howl.inputs.register {
  name: 'clipboard_item',
  description: 'Returns a specific clip from the clipboard',
  factory: -> input
}
