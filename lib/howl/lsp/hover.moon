-- Copyright 2026 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

lsp = require 'howl.lsp'
{:ActionBuffer, :markup} = howl.ui

fenced = (text, language = '') -> "```#{language}\n#{text}\n```"

-- converts hover contents, which is either a MarkupContent, a MarkedString
-- or a list of MarkedStrings, to markdown
local to_markdown
to_markdown = (contents) ->
  return nil unless contents

  text = if type(contents) == 'string'
    contents
  elseif contents.kind
    contents.kind == 'plaintext' and fenced(contents.value) or contents.value
  elseif contents.value
    fenced contents.value, contents.language
  else
    parts = {}
    for c in *contents
      part = to_markdown c
      table.insert parts, part if part
    table.concat parts, '\n\n'

  return nil if not text or text.is_blank
  text

-- returns a buffer with the server's documentation for pos, or nil. Must be
-- called from a coroutine.
doc_for = (buffer, pos) ->
  state = lsp.attach buffer
  return nil unless state
  client = state.client
  return nil if client.initialized and not client.capabilities.hoverProvider

  lsp.sync buffer
  result = client\request 'textDocument/hover', {
    textDocument: { uri: state.uri },
    position: lsp.position(buffer, pos)
  }
  return nil unless type(result) == 'table'

  text = to_markdown result.contents
  return nil unless text
  with ActionBuffer!
    \append markup.markdown(text)

:to_markdown, :doc_for
