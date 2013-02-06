import MenuPopup, style from howl.ui
import Completer from howl

class CompletionPopup extends MenuPopup

  new: (editor, pos) =>
    error('Missing argument #1: editor', 3) if not editor
    @editor = editor
    @completer = Completer @editor.buffer, pos
    comp_style = style.at_pos(@editor.buffer, @completer.start_pos) or style.default
    column_styles = { comp_style, style.comment }
    items, search = @completer\complete pos
    super items, self\_on_completed, :column_styles, highlight_matches_for: search

  @property position: get: => @completer.start_pos
  @property empty: get: => #@list.items == 0

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

  _on_completed: (item) =>
    @editor.cursor.pos = @completer\accept item, @editor.cursor.pos
    true

return CompletionPopup
