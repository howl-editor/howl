ffi = require 'ffi'
core = require 'ljglibs.core'
Type = require 'ljglibs.gobject.type'
Window = require 'ljglibs.gtk.window'

describe 'core', ->
  describe 'define(name, spec, constructor)', ->
    it 'defines a metatype for the ctype given by <name>', ->
      ffi.cdef 'typedef struct {} my_type;'
      core.define 'my_type', {my_method: -> 'ret' }
      o = ffi.new 'my_type'
      assert.equal 'ret', o\my_method!

    it 'exposes any constants given in .constants', ->
      ffi.cdef 'typedef struct {} my_type2; enum Constants { WAT = 3 };'
      MyType = core.define 'my_type2', { constants: { 'WAT' } }
      assert.equal 3, MyType.WAT

    it 'exposes any properties given in .properties', ->
      ffi.cdef 'typedef struct {} my_type3;'
      prop2 = 'unset'
      core.define 'my_type3', {
        properties: {
          my_prop: -> 'prop me up'
          prop2: {
            get: => prop2
            set: (v) => prop2 = "set-#{v}"
          }
        }
      }
      o = ffi.new 'my_type3'
      assert.equal 'prop me up', o.my_prop
      o.prop2 = 'yes'
      assert.equal 'set-yes', o.prop2

    context '(inheritance)', ->
      it 'dispatches missing methods, properties and constants to the base', ->
        ffi.cdef [[
          typedef struct {} my_base;
          enum BaseConstants { FIND_ME = 123 };
          typedef struct {} my_middle;
          enum MiddleConstants { MIDDLE_ME = 456 };
          typedef struct {} my_child;
        ]]
        core.define 'my_base', {
          constants: { 'FIND_ME' }
          properties: {
            inh_prop: =>
              assert.equal ffi.typeof('my_base *'), ffi.typeof(@)
              'from_base'
          }
          override_me: => 'base'
          meth: =>
            assert.equal ffi.typeof('my_base *'), ffi.typeof(@)
            'base_ret'
        }

        core.define 'my_middle < my_base', {
          constants: { 'MIDDLE_ME' }
          properties: {
            middle_prop: =>
              assert.equal ffi.typeof('my_middle *'), ffi.typeof(@)
              'from_middle'
          }
          override_me: =>
            assert.equal ffi.typeof('my_middle *'), ffi.typeof(@)
            'middle'
        }

        MyType = core.define 'my_child < my_middle', {}
        o = ffi.new 'my_child *'

        assert.equal 'from_base', o.inh_prop
        assert.equal 123, MyType.FIND_ME
        assert.equal 'base_ret', o\meth!

        assert.equal 'from_middle', o.middle_prop
        assert.equal 456, MyType.MIDDLE_ME
        assert.equal 'middle', o\override_me!

    context '(instance creation)', ->
      context 'when a table is passed to the constructor', ->
        it 'sets any key-value pairs as properties on the instance', ->
          ffi.cdef 'typedef struct { int foo; } my_prop_type;'
          MyPropType = core.define 'my_prop_type', {
            properties: {
              foo: {
                get: => @foo
                set: (v) => @.foo = v
              }
            }
          }, -> ffi.new 'my_prop_type'
          o = MyPropType foo: 123
          assert.equal 123, o.foo

    context '(signals)', ->
      -- we're just borrowing the Window class here to verify this

      it 'sets up signal hook functions automatically based on the gtype', ->
        win = Window!
        show_handler = spy.new ->
        win\on_show show_handler, nil, 123
        win\show!
        assert.spy(show_handler).was_called_with win, nil, 123

      it 'casts arguments of known types', ->
        win = Window!
        show_handler = (signal_win) ->
          assert.equal Window.show, signal_win.show
        win\on_show show_handler
        win\show!

  describe 'cast(gtype, instance)', ->
    it 'supports some basic types', ->
      v = ffi.cast 'void *', 1
      assert.equal 1, core.cast(Type.from_name('guint'), v)

    it 'supports ljglibs definitions', ->
      win = Window!
      v = ffi.cast 'void *', win
      win2 = core.cast(Type.from_name('GtkWindow'), v)
      assert.equals Window.new, win2.new
