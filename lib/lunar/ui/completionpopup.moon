import MenuPopup, style from lunar.ui
import Completer from lunar

class CompletionPopup extends MenuPopup

  new: (editor, pos) =>
    error('Missing argument #1: editor', 3) if not editor
    @editor = editor
    @completer = Completer @editor.buffer, pos
    comp_style = style.at_pos(@editor.buffer, @completer.start_pos) or style.default
    column_styles = { comp_style, style.comment }
    super @completer\complete(pos), self\_on_completed, :column_styles

  @property position: get: => @completer.start_pos
  @property empty: get: => #@list.items == 0

  on_char_added: (editor, args) =>
    if args.key_name == 'space'
      @close!
      return

    items = @completer\complete @editor.cursor.pos
    if #items == 0
      @close!
    else
      @items = items

  set_completions: (items) =>
    @list.items = items
    @list\show!
    @resize_for_content!

  _on_completed: (item) =>
    cur_word = @editor.current_word
    cur_word.text = item
    @editor.cursor.pos = cur_word.end_pos + 1
    true

return CompletionPopup
