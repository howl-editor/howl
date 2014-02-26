-- Copyright 2013 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

import bundle, mode, Buffer from howl
import Editor from howl.ui

describe 'Ruby mode', ->
  local m
  local buffer, editor, cursor, lines

  setup ->
    bundle.load_by_name 'ruby'
    m = mode.by_name 'ruby'

  teardown -> bundle.unload 'ruby'

  before_each ->
    buffer = Buffer m
    editor = Editor buffer
    cursor = editor.cursor
    lines = buffer.lines

  describe 'indentation support', ->
    indent_level = 2

    before_each ->
      buffer.config.indent = indent_level

    indents = {
      'pending function definitions': {
        'def foo'
      }
      'pending class declarations': {
        'class Frob',
        'class Frob < Bar',
      }
      'pending module declarations': {
        'module Frob',
      }
      'continued lines': {
        'var = ',
        'var,',
        'foo &&',
        'foo ||',
      }
      'open bracket statements': {
        'var = {',
        'other: [',
        'some(',
        '{',
        '[',
        '('
      }
      'open conditionals': {
        'if foo and bar',
        'else',
        'elsif (foo and bar) or frob',
        'elsif true',
        'while foo',
        'unless bar',
        'bar = if zed'
      }
      'block statements': {
        'foo do',
        'foo.each_pair do |my_var, other_var|',
        'begin',
      }
    }

    non_indents = {
      'closed conditionals': {
        'if foo; true; end',
        'elseif foo; true; end',
        'unless foo; true; end',
        'bar = if zed; "zed"; else "foo"; end'
      },
      'statement modifiers': {
        'bar unless foo',
        'foo if zed',
      }
      'miscellaneous non-indenting statements': {
        'foo = bar',
        'foo = bar frob zed'
        'foo = not bar(frob zed) if true'
        'motif some'
        'dojo_style foo'
        'one for two'
      }
    }

    dedents = {
      'block starters': {
        'else',
        'elsif foo',
      }
      'block enders': {
        '}',
        'end',
      }
    }

    for desc in pairs indents
      context 'indents one level for a line after ' .. desc, ->
        for code in *indents[desc]
          it "e.g. indents for '#{code}'", ->
            buffer.text = code .. '\n'
            cursor.line = 2
            editor\indent!
            assert.equal indent_level, editor.current_line.indentation

    it 'disregards empty lines above when determining indent', ->
      for desc in pairs indents
        for code in *indents[desc]
          buffer.text = code .. '\n\n'
          cursor.line = 3
          editor\indent!
          assert.equal indent_level, editor.current_line.indentation


    for desc in pairs dedents
      context 'dedents one level for a line containing ' .. desc, ->
        for code in *dedents[desc]
          it "e.g. dedents for '#{code}'", ->
            buffer.text = '  foo\n  ' .. code
            cursor.line = 2
            editor\indent!
            assert.equal 0, editor.current_line.indentation

    for desc in pairs non_indents
      context 'keeps the current indent for a line after ' .. desc, ->
        for code in *non_indents[desc]
          it "e.g. does not indent for '#{code}'", ->
            buffer.text = "  #{code}\n  "
            cursor.line = 2
            editor\indent!
            assert.equal 2, editor.current_line.indentation

    it 'keeps the current indent for subsequent continued lines', ->
      buffer.text = "foo,\n  bar,\n"
      cursor.line = 3
      editor\indent!
      assert.equal 2, editor.current_line.indentation

    it 'does not indent after continued lines that first in a block', ->
      buffer.text = "{\n  foo,\nwat"
      editor\indent_all!
      assert.equal 2, lines[3].indentation

    it 'does not indent after continued lines that are hash entries', ->
      buffer.text = "foo: true,\n'bar' => true,\n"
      editor\indent_all!
      assert.equal 0, lines[2].indentation
      assert.equal 0, lines[3].indentation

    it 'dedents after a finished continuation block', ->
      buffer.text = "start do\n  bar +\n    foo+\n    bar\n"
      cursor.line = 5
      editor\indent!
      assert.equal 2, editor.current_line.indentation

    it 'dedents after a finished continuation block of hash entries', ->
      buffer.text = "h = {\n  bar: true,\n  foo: false\n"
      cursor.line = 4
      editor\indent!
      assert.equal 0, editor.current_line.indentation

    it 'double-dedents after a finished continuation block for ending tokens', ->
      buffer.text = "start do\n  bar +\n    foo\n    end"
      cursor.line = 4
      editor\indent!
      assert.equal 0, editor.current_line.indentation
