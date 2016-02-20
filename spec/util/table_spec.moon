{:delegate_to} = howl.util.table

describe 'table utilities', ->
  describe 'delegate_to(base, overlay_t)', ->
    it 'overlays the <overlay_t> table over the <base> table', ->
      base = foo: 1, bar: { sub: 'b' }
      over = zed: 3
      o = delegate_to base, over
      assert.equal 1, o.foo
      assert.equal 3, o.zed
      assert.equal 'b', o.bar.sub

    it 'the overlay is applied recursively and partially', ->
      base = sub: { a: 'a', b: 'b', deep: { x: 'x' } }
      over = sub: { a: 'A', c: 'c', deep: { y: 'Y' } }
      o = delegate_to base, over
      assert.equal 'A', o.sub.a
      assert.equal 'b', o.sub.b
      assert.equal 'c', o.sub.c
      assert.equal 'Y', o.sub.deep.y
      assert.equal 'x', o.sub.deep.x

    it 'does not change the metatable of either argument', ->
      base_mt = __index: { foo: 1, bar: 'x' }
      base = setmetatable {}, base_mt

      over_mt = __index: { foo: 'foo', zed: 'y' }
      over = setmetatable {}, over_mt

      o = delegate_to base, over
      assert.equal 'foo', o.foo
      assert.equal 'x', o.bar
      assert.equal 'y', o.zed
      assert.equal base_mt, getmetatable(base)
      assert.equal over_mt, getmetatable(over)

    it 'provides a joint view of the keys for pairs()', ->
      base = foo: 1, bar: 'b'
      over = zed: 3, bar: 'B'
      o = delegate_to base, over
      assert.same {foo: 1, bar: 'B', zed: 3}, {k,v for k, v in pairs(o)}
