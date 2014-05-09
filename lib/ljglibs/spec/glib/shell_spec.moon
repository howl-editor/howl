shell = require 'ljglibs.glib.shell'

describe 'shell', ->
  describe 'parse_argv(command_line)', ->
    it 'parses a command line into an argument table', ->
      assert.same { 'foo' }, shell.parse_argv 'foo'
      assert.same { 'foo', 'bar' }, shell.parse_argv 'foo bar'
      assert.same { 'foo', 'bar zed' }, shell.parse_argv 'foo "bar zed"'
      assert.same { 'foo', 'bar zed' }, shell.parse_argv "foo 'bar zed'"

  describe 'quoting', ->
    it 'quote and unquote allows quoting strings for the shell', ->
      orig = 'My fine argument'
      quoted = shell.quote orig
      assert.not_equals orig, quoted
      assert.equals orig, shell.unquote quoted
