{:app, :Buffer, :command, :mode} = howl
require 'howl.variables.core_variables'
require 'howl.commands.edit_commands'

describe 'edit commands', ->
  describe 'the goto command', ->
    local buffer, editor, run

    before_each ->
      editor = app.editor
      run = command.run
      command.run = spy.new ->
      buffer = Buffer mode.by_name 'default'
      buffer.text = 'foo bar'

    after_each ->
      app.editor = editor
      command.run = run

    goto_with_client = (client) ->
      buffer.data.lsp = :client
      app.editor = :buffer, current_context: buffer\context_at(1), show_popup: spy.new ->
      command.get('goto').handler!

    it 'searches the project when the buffer has no language server', ->
      app.editor = :buffer
      command.get('goto').handler!
      assert.spy(command.run).was_called_with 'project-file-search'

    it 'searches the project when the language server supports no goto requests', ->
      goto_with_client initialized: true, capabilities: {}
      assert.spy(command.run).was_called_with 'project-file-search'
      assert.spy(app.editor.show_popup).was_not_called!

    it 'shows a menu when the language server supports a goto request', ->
      goto_with_client initialized: true, capabilities: { definitionProvider: true }
      assert.spy(app.editor.show_popup).was_called!
      assert.spy(command.run).was_not_called!
