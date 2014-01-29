ffi = require 'ffi'
core = require 'ljglibs.core'
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
      Type = core.define 'my_type2', { constants: { 'WAT' } }
      assert.equal 3, Type.WAT

    it 'exposes any properties given in .properties', ->
      ffi.cdef 'typedef struct {} my_type3;'
      core.define 'my_type3', { properties: { my_prop: -> 'prop me up' } }
      o = ffi.new 'my_type3'
      assert.equal 'prop me up', o.my_prop

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

        Type = core.define 'my_child < my_middle', {}
        o = ffi.new 'my_child *'

        assert.equal 'from_base', o.inh_prop
        assert.equal 123, Type.FIND_ME
        assert.equal 'base_ret', o\meth!

        assert.equal 'from_middle', o.middle_prop
        assert.equal 456, Type.MIDDLE_ME
        assert.equal 'middle', o\override_me!

    context '(signals)', ->
      it 'sets up signal hook functions automatically based on the gtype', ->
        -- we're just borrowing the Window class here to verify this
        win = Window!
        show_handler = spy.new ->
        win\on_show show_handler, 123
        win\show!
        assert.spy(show_handler).was_called_with win, 123
