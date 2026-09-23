uri = require 'howl.lsp.uri'
{:File} = howl.io

describe 'lsp.uri', ->
  describe 'for_file(file)', ->
    it 'returns a file URI for the file', ->
      assert.equals 'file:///tmp/foo/bar.py', uri.for_file File('/tmp/foo/bar.py')

    it 'percent-encodes reserved and non-ASCII characters', ->
      assert.equals 'file:///tmp/my%20d%C3%A5r/a%23b.py', uri.for_file File('/tmp/my dår/a#b.py')

  describe 'to_path(uri)', ->
    it 'returns the decoded path for a file URI', ->
      assert.equals '/tmp/my dår/a#b.py', uri.to_path 'file:///tmp/my%20d%C3%A5r/a%23b.py'

    it 'returns nil for non-file URIs', ->
      assert.is_nil uri.to_path 'https://howl.io'
