-- Copyright 2018 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import bundle, mode, Buffer from howl
import Editor from howl.ui

describe 'C mode', ->
  local m
  local buffer, editor, lines

  setup ->
    bundle.load_by_name 'c'
    m = mode.by_name 'c'

  teardown -> bundle.unload 'c'

  before_each ->
    buffer = Buffer m
    editor = Editor buffer
    lines = buffer.lines

  describe 'structure()', ->
    assert_lines = (expected, actual) ->
      assert.same ["#{l.nr}: #{l}" for l in *expected], ["#{l.nr}: #{l}" for l in *actual]

    it 'includes function declarations in the structure', ->
      buffer.text = trimmed_text [[
        int example_line_1 (const char *s) {
        }

        void *
        broken_up_line_5 (int32_t foo)
        {
        }

        void broken_args_line_9(int first,
          void *second) {
          }

        int broken_again_line_13(int first,
          char continue)
        {
        }
      ]]

      assert_lines {
        lines[1],
        lines[5],
        lines[9],
        lines[13]
      }, m\structure editor

    it 'includes struct declarations in the structure', ->
      buffer.text = trimmed_text [[
        struct Foo_Line1 {
          int bar;
        }
        struct Bar_Line4
        {
        }
      ]]

      assert_lines {
        lines[1],
        lines[4],
      }, m\structure editor

    it 'includes class declarations in the structure', ->
      buffer.text = trimmed_text [[
        class Foo_Line1 {
        }
        class Bar_Line3
        {
        }
        class Zed_Line6 : Base {
        }
      ]]

      assert_lines {
        lines[1],
        lines[3],
        lines[6],
      }, m\structure editor

    it 'includes namespaces in the structure', ->
      buffer.text = trimmed_text [[
        namespace Foo {
          namespace Bar {
          }
        }
      ]]

      assert_lines {
        lines[1],
        lines[2],
      }, m\structure editor

    it 'includes C++ const functions in the structure', ->
      buffer.text = trimmed_text [[
        int example_line_1 (const char *s) const {
        }

        void *
        broken_up_line_5 (int32_t foo) const
        {
        }

        void broken_args_line_9(int first,
          void *second) const {
          }

        int broken_again_line_13(int first,
          char continue) const
        {
        }
      ]]

      assert_lines {
        lines[1],
        lines[5],
        lines[9],
        lines[13]
      }, m\structure editor

    it 'handles C++ class constructs', ->
      buffer.text = trimmed_text [[
        class Test
        {
            private:
                int data1;

            public:
                void function1() {
                  data1 = 2;
                }

                float function2()
                {
                    return data1;
                }
           };
      ]]

      assert_lines {
        lines[1],
        lines[3],
        lines[6],
        lines[7],
        lines[11],
      }, m\structure editor

    it 'handles C++ class constructs', ->
      buffer.text = trimmed_text [[
        Foo::Foo(QObject *parent) :
            QObject(parent) {
            }
      ]]

      assert_lines {
        lines[1],
      }, m\structure editor

    it 'handles trailing comments in various places', ->
      buffer.text = trimmed_text [[
        int example_line_1 (const char *s) { /* wat wat */
        }

        void *
        broken_up_line_5 (int32_t foo) // c++ wat
        { /* close me! */
        }

        void broken_args_line_9(int first, // first wat
          void *second) {  /* second wat */
          }

        int broken_again_line_13(int first, // ugh
          char continue) // blargh
        { // cloooooseee!
        }
      ]]

      assert_lines {
        lines[1],
        lines[5],
        lines[9],
        lines[13]
      }, m\structure editor

    it 'is not confused by irrelevant stuff', ->
      buffer.text = trimmed_text [[
        #if DEF
        int bar(void *other_p) {
          void *p = (struct Bar *)other_p;
          try {
            if (cond) {
            }
          } catch() {
          }
          if (call(one,
            two)) {
            }
        }
        #endif
      ]]

      assert_lines {
        lines[2],
      }, m\structure editor
