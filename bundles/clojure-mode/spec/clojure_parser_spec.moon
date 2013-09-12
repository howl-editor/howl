import bundle, Buffer from howl

describe 'clojure_parser', ->
  local parser, buffer
   -- local buffer, editor, cursor, lines

  setup ->
    bundle.load_by_name 'clojure-mode'
    parser = bundles.clojure_mode.parser
    buffer = Buffer!

  context 'parse(buffer)', ->
    context 'namespaces', ->
      it 'parses the namespace name', ->
        buffer.text = '(ns foo.bar)'
        assert.equal 'foo.bar', parser.parse(buffer).ns.name
