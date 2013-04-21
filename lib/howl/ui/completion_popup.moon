import MenuPopup, style from howl.ui
import Completer from howl

class CompletionPopup extends MenuPopup

  new: (editor) =>
    error('Missing argument #1: editor', 3) if not editor
    @editor = editor
    @candidates = {}
    super {}, self\_on_completed

  @property position: get: => @completer.start_pos
  @property empty: get: => #@candidates == 0

  complete: =>
    @_init_completer!
    @candidates, @search = @completer\complete @editor.cursor.pos

  show: (...) =>
    @items = @candidates
    @list.highlight_matches_for = @search
    super ...

  close: =>
    @completer = nil
    super!

  on_char_added: (editor, args) =>
    if args.key_name == 'space'
      @close!
      return

    items, search = @completer\complete @editor.cursor.pos
    if #items == 0
      @close!
    else
      @list.highlight_matches_for = search
      @items = items

  on_text_deleted: (editor, args) =>
    if args.at_pos < @completer.start_pos or editor.current_line != @completer.line
      @close!
      return

  _init_completer: =>
    @completer = Completer @editor.buffer, @editor.cursor.pos
    comp_style = style.at_pos(@editor.buffer, @completer.start_pos) or style.default
    @list.column_styles = { comp_style, style.comment }

  _on_completed: (item) =>
    @editor.cursor.pos = @completer\accept item, @editor.cursor.pos
    true

return CompletionPopup
