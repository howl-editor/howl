rename_view = require 'howl.lsp.rename_view'
{:app} = howl
{:File} = howl.io
{:highlight} = howl.ui

key = (name) -> {
  key_name: name, alt: false, control: false, meta: false, shift: false, super: false
}

describe 'lsp.rename_view', ->
  describe 'read_name(opts)', ->
    local dir, file, buffer, editor, load

    loc = (line_nr, start, stop) ->
      line = buffer.lines[line_nr]
      { "x.py:#{line_nr}", line.text, :file, :line_nr, byte_start_column: start, byte_end_column: stop }

    rows = (command_line) ->
      [{ item[2], item.item_highlights[2] } for item in *command_line\get_widget('locations').list.items]

    notification = (command_line) -> command_line.notification.text_widget.buffer.text

    before_each ->
      dir = File.tmpdir!
      file = dir\join 'x.py'
      file.contents = 'åä föö = föö + 1\nprint(föö)\n'
      buffer = app\new_buffer!
      buffer.file = file
      editor = app.editor
      app.editor = preview: spy.new(->), cancel_preview: spy.new(->)
      load = -> { loc(1, 6, 11), loc(1, 14, 19), loc(2, 7, 12) }, nil

    after_each ->
      app.editor = editor
      if app.window
        app.window\destroy!
        app.window = nil
      app\close_buffer buffer, true
      dir\delete_all!

    read = (f) ->
      local result
      within_command_line (-> result = rename_view.read_name title: 'Rename', text: 'föö', load: -> load!), f
      result

    it 'lists one row per line, highlighting the name in each place', ->
      local listed
      read (command_line) -> listed = rows command_line
      assert.same {
        { 'åä föö = föö + 1', {
          { byte_start_column: 6, byte_end_column: 11 },
          { byte_start_column: 14, byte_end_column: 19 }
        } },
        { 'print(föö)', { { byte_start_column: 7, byte_end_column: 12 } } }
      }, listed

    it 'shows the entered name in place of the old one as it is typed', ->
      local listed
      read (command_line) ->
        command_line\write 'x'
        listed = rows command_line
      assert.same {
        { 'åä fööx = fööx + 1', {
          { byte_start_column: 6, byte_end_column: 12 },
          { byte_start_column: 15, byte_end_column: 21 }
        } },
        { 'print(fööx)', { { byte_start_column: 7, byte_end_column: 13 } } }
      }, listed

    it 'replaces a place continuing on later lines up to the end of its first', ->
      load = -> { loc(1, 14, 14) }
      local listed
      read (command_line) -> listed = rows command_line
      assert.same { { 'åä föö = föö', { { byte_start_column: 14, byte_end_column: 19 } } } }, listed

    it 'selects the row of the selected location', ->
      locations = { loc(1, 6, 11), loc(2, 7, 12) }
      load = -> locations, locations[2]
      local selected
      read (command_line) ->
        selected = command_line\get_widget('locations').list.selection
      assert.equals 2, selected.line_nr

    it 'keeps the selection when the name changes', ->
      local selected
      read (command_line) ->
        command_line\handle_keypress key('down')
        command_line\write 'x'
        selected = command_line\get_widget('locations').list.selection
      assert.equals 2, selected.line_nr

    it 'previews the selected row, highlighting its places', ->
      local previewed, highlighted
      app.editor.preview = (b) => previewed = b
      read (command_line) ->
        highlighted = [p for p = 1, buffer.length when highlight.at_pos(buffer, p)[1] == 'search']
      assert.equals buffer, previewed
      assert.same { 4, 5, 6, 10, 11, 12 }, highlighted

    it 'shows the number of places and files', ->
      local text
      read (command_line) -> text = notification command_line
      assert.equals '3 places in 1 file', text

    it 'shows the message from load when it finds nothing', ->
      load = -> nil, 'Nothing here'
      local text, listed
      read (command_line) ->
        text = notification command_line
        listed = command_line\get_widget('locations').list.items
      assert.equals 'Nothing here', text
      assert.same {}, listed

    it 'shows the error when load fails', ->
      load = -> error 'server gone', 0
      local text
      read (command_line) -> text = notification command_line
      assert.equals 'server gone', text

    it 'returns the entered name on enter', ->
      result = read (command_line) ->
        command_line\write 'x'
        command_line\handle_keypress key('return')
      assert.equals 'fööx', result

    it 'returns nil on escape', ->
      result = read (command_line) ->
        command_line\handle_keypress key('escape')
      assert.is_nil result
