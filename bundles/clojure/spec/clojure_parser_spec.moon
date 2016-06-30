import bundle, Buffer from howl

describe 'clojure_parser', ->
  local parser, buffer

  setup ->
    bundle.load_by_name 'clojure'
    parser = _G.bundles.clojure.parser
    buffer = Buffer!

  context 'parse(buffer)', ->
    context 'namespaces', ->
      it 'parses the namespace name', ->
        buffer.text = '(ns foo.bar)'
        assert.equal 'foo.bar', parser.parse(buffer).ns.name
