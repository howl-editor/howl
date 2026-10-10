edits = require 'howl.lsp.edits'
uri = require 'howl.lsp.uri'
{:app, :Buffer} = howl
{:File} = howl.io

range = (line, s_char, e_line, e_char) -> {
  start: { :line, character: s_char },
  ['end']: { line: e_line, character: e_char }
}

edit = (text, ...) -> { range: range(...), newText: text }

describe 'lsp.edits', ->
  describe 'apply_text_edits(buffer, edits)', ->
    local buffer

    before_each ->
      buffer = Buffer {}
      buffer.text = 'åäö\nxÅy'

    it 'replaces, inserts and deletes text at utf-8 positions', ->
      assert.is_true edits.apply_text_edits buffer, {
        edit 'Ä', 0, 2, 0, 4
        edit '!', 1, 3, 1, 3
        edit '', 1, 0, 1, 1
      }
      assert.equals 'åÄö\nÅ!y', buffer.text

    it 'applies the edits as one undo step', ->
      edits.apply_text_edits buffer, { edit('A', 0, 0, 0, 2), edit('Y', 1, 3, 1, 4) }
      assert.equals 'Aäö\nxÅY', buffer.text
      buffer\undo!
      assert.equals 'åäö\nxÅy', buffer.text

    it 'keeps the order of inserts at the same position', ->
      edits.apply_text_edits buffer, { edit('1', 1, 0, 1, 0), edit('2', 1, 0, 1, 0) }
      assert.equals 'åäö\n12xÅy', buffer.text

    it 'inserts before a replacement starting at the same position', ->
      edits.apply_text_edits buffer, { edit('X', 1, 0, 1, 1), edit('<', 1, 0, 1, 0) }
      assert.equals 'åäö\n<XÅy', buffer.text

    it 'treats a character beyond the end of its line as the end of the line', ->
      edits.apply_text_edits buffer, { edit('!', 0, 99, 0, 99) }
      assert.equals 'åäö!\nxÅy', buffer.text

    it 'treats a line beyond the last one as the end of the buffer', ->
      edits.apply_text_edits buffer, { edit('', 0, 6, 5, 0) }
      assert.equals 'åäö', buffer.text

    it 'handles lines ending with \\r\\n', ->
      buffer.text = 'åä\r\nö\r\n'
      edits.apply_text_edits buffer, { edit('Ö', 1, 0, 1, 2), edit('', 0, 4, 1, 0) }
      assert.equals 'åäÖ\r\n', buffer.text

    it 'refuses overlapping edits, leaving the buffer unchanged', ->
      status, err = edits.apply_text_edits buffer, { edit('a', 0, 0, 0, 4), edit('b', 0, 2, 0, 6) }
      assert.is_nil status
      assert.match err, 'overlapping'
      assert.equals 'åäö\nxÅy', buffer.text

    it 'refuses to edit read-only buffers', ->
      buffer.read_only = true
      status, err = edits.apply_text_edits buffer, { edit('a', 0, 0, 0, 0) }
      assert.is_nil status
      assert.match err, 'read%-only'

  describe 'apply_workspace_edit(edit)', ->
    local dir, a, b, a_buffer

    doc = (file, list, version) ->
      { textDocument: { uri: uri.for_file(file), :version }, edits: list }

    buffer_of = (file) ->
      for buffer in *app.buffers
        return buffer if buffer.file == file

    attach = (buffer, version = 1) ->
      client = notify: spy.new ->
      state = { :client, uri: uri.for_file(buffer.file), :version, dirty: false, changes: {}, full: false }
      buffer.data.lsp = state
      state

    before_each ->
      dir = File.tmpdir!
      a = dir\join 'a.txt'
      b = dir\join 'b.txt'
      a.contents = 'åäö\n'
      b.contents = 'xÅy\n'
      a_buffer = app\new_buffer!
      a_buffer.file = a

    after_each ->
      for buffer in *[buf for buf in *app.buffers when buf.file and buf.file\is_below(dir)]
        app\close_buffer buffer, true
      dir\delete_all!

    it 'applies the edits in changes to the buffers of their files', ->
      b_buffer = app\new_buffer!
      b_buffer.file = b
      result = edits.apply_workspace_edit changes: {
        [uri.for_file(a)]: { edit('Ä', 0, 2, 0, 4) }
        [uri.for_file(b)]: { edit('Y', 0, 3, 0, 4) }
      }
      assert.equals 'åÄö\n', a_buffer.text
      assert.equals 'xÅY\n', b_buffer.text
      assert.equals 2, #result.buffers

    it 'applies the edits in documentChanges', ->
      result = edits.apply_workspace_edit documentChanges: { doc(a, { edit('Ä', 0, 2, 0, 4) }) }
      assert.equals 'åÄö\n', a_buffer.text
      assert.equals a_buffer, result.buffers[1]

    it 'writes the edits of files that are not open to them, without opening them', ->
      result = edits.apply_workspace_edit documentChanges: { doc(b, { edit('Y', 0, 3, 0, 4) }) }
      assert.equals 'xÅY\n', b.contents
      assert.is_nil buffer_of b
      assert.equals b, result.written[1]
      assert.same {}, result.buffers

    it 'saves open buffers that had no other changes', ->
      result = edits.apply_workspace_edit documentChanges: { doc(a, { edit('Ä', 0, 2, 0, 4) }) }
      assert.equals 'åÄö\n', a.contents
      assert.is_false a_buffer.modified
      assert.equals a_buffer, result.saved[1]

    it 'saves showing buffers as well', ->
      a_buffer\add_view_ref!
      edits.apply_workspace_edit documentChanges: { doc(a, { edit('Ä', 0, 2, 0, 4) }) }
      a_buffer\remove_view_ref!
      assert.equals 'åÄö\n', a.contents
      assert.is_false a_buffer.modified

    it 'leaves buffers with other unsaved changes unsaved', ->
      a_buffer\append '!'
      attach a_buffer
      edits.apply_workspace_edit documentChanges: { doc(a, { edit('Ä', 0, 2, 0, 4) }) }
      assert.equals 'åÄö\n!', a_buffer.text
      assert.is_true a_buffer.modified
      assert.equals 'åäö\n', a.contents

    it 'applies the edits of each buffer as one undo step', ->
      edits.apply_workspace_edit documentChanges: {
        doc a, { edit('A', 0, 0, 0, 2), edit('Ö', 0, 4, 0, 6) }
      }
      assert.equals 'AäÖ\n', a_buffer.text
      a_buffer\undo!
      assert.equals 'åäö\n', a_buffer.text

    it 'skips documents without edits', ->
      result = edits.apply_workspace_edit documentChanges: { doc(a, {}), doc(b, {}) }
      assert.same {}, result.buffers
      assert.same {}, result.written
      assert.is_false a_buffer.modified

    context 'when any part of the edit cannot be applied', ->
      refused = (workspace_edit, pattern) ->
        result, err = edits.apply_workspace_edit workspace_edit
        assert.is_nil result
        assert.match err, pattern
        assert.equals 'åäö\n', a_buffer.text
        assert.equals 'xÅy\n', b.contents

      it 'changes nothing for a file that does not exist', ->
        refused {
          documentChanges: {
            doc b, { edit('Y', 0, 3, 0, 4) }
            doc a, { edit('Ä', 0, 2, 0, 4) }
            doc dir\join('none.txt'), { edit('x', 0, 0, 0, 0) }
          }
        }, 'does not exist'

      it 'changes nothing for overlapping edits', ->
        refused {
          documentChanges: {
            doc b, { edit('Y', 0, 3, 0, 4) }
            doc a, { edit('x', 0, 0, 0, 4), edit('y', 0, 2, 0, 6) }
          }
        }, 'overlapping'

      it 'changes nothing for several edits of the same document', ->
        refused {
          documentChanges: {
            doc b, { edit('Y', 0, 3, 0, 4) }
            doc a, { edit('Ä', 0, 2, 0, 4) }
            doc a, { edit('Ö', 0, 4, 0, 6) }
          }
        }, 'several edits'

      it 'changes nothing for a read-only buffer', ->
        a_buffer.read_only = true
        refused {
          documentChanges: {
            doc b, { edit('Y', 0, 3, 0, 4) }
            doc a, { edit('Ä', 0, 2, 0, 4) }
          }
        }, 'read%-only'

      it 'changes nothing for resource operations', ->
        refused {
          documentChanges: {
            doc a, { edit('Ä', 0, 2, 0, 4) }
            { kind: 'create', uri: uri.for_file(dir\join('new.txt')) }
          }
        }, "unsupported operation 'create'"

      it 'changes nothing for a file that is not valid UTF-8', ->
        bad = dir\join 'bad.txt'
        bad.contents = 'x\255\n'
        refused {
          documentChanges: {
            doc b, { edit('Y', 0, 3, 0, 4) }
            doc bad, { edit('y', 0, 0, 0, 1) }
          }
        }, 'valid UTF%-8'

      it 'changes nothing for a file that is not writeable', ->
        locked = dir\join 'locked.txt'
        locked.contents = 'x\n'
        os.execute "chmod a-w '#{locked.path}'"
        refused {
          documentChanges: {
            doc b, { edit('Y', 0, 3, 0, 4) }
            doc locked, { edit('y', 0, 0, 0, 1) }
          }
        }, 'not writeable'

      it 'changes nothing for uris that are not files', ->
        refused {
          documentChanges: {
            doc b, { edit('Y', 0, 3, 0, 4) }
            { textDocument: { uri: 'untitled:x' }, edits: { edit('x', 0, 0, 0, 0) } }
          }
        }, 'unsupported uri'

    context 'for text the server has not seen', ->
      it 'refuses edits of attached buffers with changes not yet sent', ->
        state = attach a_buffer
        state.dirty = true
        result, err = edits.apply_workspace_edit documentChanges: { doc(a, { edit('Ä', 0, 2, 0, 4) }) }
        assert.is_nil result
        assert.match err, 'has changed'

      it 'refuses edits for another version of an attached buffer', ->
        attach a_buffer, 3
        result = edits.apply_workspace_edit documentChanges: { doc(a, { edit('Ä', 0, 2, 0, 4) }, 2) }
        assert.is_nil result
        assert.equals 'åäö\n', a_buffer.text
        edits.apply_workspace_edit documentChanges: { doc(a, { edit('Ä', 0, 2, 0, 4) }, 3) }
        assert.equals 'åÄö\n', a_buffer.text

      it 'refuses edits of unattached buffers with unsaved changes', ->
        a_buffer.text = 'changed\n'
        result, err = edits.apply_workspace_edit changes: { [uri.for_file(a)]: { edit('x', 0, 0, 0, 1) } }
        assert.is_nil result
        assert.match err, 'unsaved changes'

    it 'sends the changes of attached buffers to the server right away', ->
      state = attach a_buffer
      edits.apply_workspace_edit documentChanges: { doc(a, { edit('Ä', 0, 2, 0, 4) }, 1) }
      notify = state.client.notify
      assert.spy(notify).was_called_with state.client, 'textDocument/didChange', {
        textDocument: { uri: uri.for_file(a), version: 2 },
        contentChanges: { { text: 'åÄö\n' } }
      }
      assert.is_false state.dirty

  describe 'on_apply_edit(params)', ->
    it 'returns applied: true when the edit was applied', ->
      with_tmpdir (dir) ->
        file = dir\join 'x.txt'
        file.contents = 'åäö'
        result = edits.on_apply_edit edit: { changes: { [uri.for_file(file)]: { edit('Ä', 0, 2, 0, 4) } } }
        assert.same { applied: true }, result
        assert.equals 'åÄö', file.contents

    it 'returns applied: false with the reason otherwise, and logs it', ->
      warn = spy.on log, 'warn'
      result = edits.on_apply_edit label: 'Rename', edit: { changes: { ['untitled:x']: { edit('x', 0, 0, 0, 0) } } }
      log.warn\revert!
      assert.is_false result.applied
      assert.match result.failureReason, 'unsupported uri'
      assert.spy(warn).was_called!
