-- Copyright 2016 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

{:parse} = howl.io.process_output
{:File} = howl.io

describe 'process_output', ->
  describe 'parse(output, opts = {})', ->
    it 'parses out line numbers and messages', ->
      assert.same {
        { line_nr: 2, message: 'foo' }
      }, parse "2: foo"

    context 'when opts.max_message_length is specified', ->
      it 'shortens the messages as neccessary', ->
      assert.same {
        { line_nr: 1, message: '123åäö..' }
      }, parse "1: 123åäö789", max_message_length: 8

    it 'parses out relevant tokens', ->
      assert.same {
        {
          line_nr: 3,
          message: "unused: `foo`, 'bar', ‘zed’",
          tokens: {'foo', 'bar', 'zed'}
        }
      }, parse "3: unused: `foo`, 'bar', ‘zed’"

    it 'parses out columns where available', ->
      assert.same {
        { line_nr: 2, column: 12, message: 'foo' }
      }, parse "2:12: foo"

    context 'file references', ->
      it 'parses out and resolves file references according to the directory option', ->
        with_tmpdir (dir) ->
          assert.same {
            { file: dir\join('zed.moon'), path: 'zed.moon', line_nr: 3, message: 'msg' }
          }, parse "zed.moon:3: msg", directory: dir

      it 'defaults to the current working directory if the directory option is missing', ->
        glib = require 'ljglibs.glib'
        cwd = File glib.get_current_dir!
        assert.same {
          { file: cwd\join('zed.moon'), path: 'zed.moon', line_nr: 3, message: 'msg' }
        }, parse "zed.moon:3: msg"

      it 'leaves absolute paths alone', ->
        assert.same {
          {
            file: File('/tmp/zed.moon'),
            path: '/tmp/zed.moon',
            line_nr: 3,
            message: 'msg'
          }
        }, parse "/tmp/zed.moon:3: msg"

      it 'leaves "-" paths alone', ->
        assert.same {
          { path: '-', line_nr: 3, message: 'msg' }
        }, parse "-:3: msg"

    context '(formats)', ->
      it 'handles sparse line and column information', ->
        assert.same {
          {line_nr: 3, column: 2, message: 'foo'}
        }, parse "3:2:foo"
