-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import MenuPopup, style from howl.ui
import Completer from howl

is_character = (event) ->
  event.character and event.character\umatch r'[\\pL_]'

class CompletionPopup extends MenuPopup

  new: (editor) =>
    error('Missing argument #1: editor', 3) if not editor
    @editor = editor
    super {}, @\_on_completed

  @property position: get: => @completer.start_pos
  @property empty: get: => #@items == 0

  complete: =>
    @_init_completer!
    @_load_completions!

  close: =>
    @completer = nil
    super!

  on_char_added: (editor, args) =>
    return unless @completer
    unless is_character args
      @close!
      return

    @_load_completions!

  on_text_deleted: (editor, args) =>
    return unless @completer
    if args.at_pos < @completer.start_pos or editor.current_line != @completer.line
      @close!
      return

  _init_completer: =>
    @completer = Completer @editor.buffer, @editor.cursor.pos
    comp_style = style.at_pos(@editor.buffer, @completer.start_pos) or 'default'
    @list.columns = { { style: comp_style } }

  _load_completions: =>
    @items, @highlight_matches_for = @completer\complete @editor.cursor.pos

    if #@items > 0
      @refresh!
      @resize!
    else
      @close!

  _on_completed: (item) =>
    @editor.cursor.pos = @completer\accept item, @editor.cursor.pos
    true

return CompletionPopup
