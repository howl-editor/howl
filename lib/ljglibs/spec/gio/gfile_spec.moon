GFile = require 'ljglibs.gio.gfile'

describe 'GFile', ->
  tmpfile = ->
    file = File assert os.tmpname!
    file.touch if not file.exists
    file

  it '.path contains the path', ->
    assert.equals '/bin/ls', GFile('/bin/ls').path

  it '.uri contains an URI representing the path', ->
    assert.equal 'file:///foo.txt', GFile('/foo.txt').uri

  it '.exists returns true if the path exists', ->
   assert.is_true GFile('/bin/ls').exists
   assert.is_false GFile('/pleasedontputadirectorylikethisinyourroot').exists

  it '.parent return the parent of the file', ->
    assert.equal '/bin', GFile('/bin/ls').parent.path

  describe 'get_child(name)', ->
    it 'returns a new file for the given child', ->
      parent = GFile '/bin'
      assert.equals '/bin/ls', parent\get_child('ls').path

  describe 'has_parent([file])', ->
    it 'returns true if the file has a parent', ->
      assert.is_true GFile('/bin/ls')\has_parent!
      assert.is_false GFile('/')\has_parent!

    context 'when <file> is provided', ->
      it 'returns true if <file> is a parent', ->
        assert.is_true GFile('/bin/ls')\has_parent GFile('/bin')

  describe 'get_relative_path(parent, descendant)', ->
    it 'returns a path relative to <parent> for <descendant>', ->
      parent = GFile '/bin'
      descendant = GFile '/bin/ls'
      assert.equal 'ls', GFile.get_relative_path parent, descendant

  describe 'query_info(attributes, flags)', ->
    context 'when the file does not exist', ->
      it 'raises an error', ->
        f = GFile '/dsfkj/sdkjs/akjd/sdjkj'
        assert.raises 'no such file', -> f\query_info '*', GFile.QUERY_INFO_NONE

    context 'for an existing file', ->
      it 'returns an info object', ->
        f = GFile '/bin/ls'
        info = f\query_info '*', GFile.QUERY_INFO_NONE
        assert.is_false info.is_hidden
        assert.is_false info.is_symlink
        assert.equal info.TYPE_REGULAR, info.filetype
        assert.is_true info\get_attribute_boolean 'access::can-read'

  describe 'load_contents()', ->
    it 'returns the contents of the file', ->
      p = os.tmpname!
      fh = io.open p, 'w'
      fh\write 'my content!'
      fh\close!

      assert.equal 'my content!', GFile(p)\load_contents!

  describe 'meta methods', ->

    it 'tostring returns the path as a string', ->
      collectgarbage!
      file = GFile '/bin/ls'
      assert.equal '/bin/ls', tostring file
