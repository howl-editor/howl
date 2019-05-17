require 'howl.ui.icons.font_awesome'  -- icons required by DirectoryExplorer
{:DirectoryExplorer} = howl.explorers
{:File} = howl.io

describe 'DirectoryExplorer', ->
  local tmp_root, subdir1, subdir2

  items = (explorer) ->
    names = [row.path for row in *explorer\display_items!]
    table.sort names, (a, b) -> a < b
    names

  before_each ->
    tmp_root = File.tmpdir!
    subdir1 = tmp_root .. 'subdir1/'
    subdir1\mkdir!
    subdir2 = tmp_root .. 'subdir2/'
    subdir2\mkdir!

    f1 = tmp_root .. 'file1'
    f1\touch!
    f2 = tmp_root .. 'file2'
    f2\touch!
    f3 = subdir1 .. 'file3'
    f3\touch!

  it 'displays the file path', ->
    e = DirectoryExplorer tmp_root
    assert.same tmp_root.path .. File.separator, e\display_path!.text

  it 'for_path returns a list of explorers from root to given path', ->
    deep_dir = tmp_root .. 'a/b/c'
    deep_dir\mkdir_p!
    es = DirectoryExplorer.for_path deep_dir.path, root: tmp_root
    assert.same 4, #es
    assert.same deep_dir\relative_to_parent(tmp_root) .. File.separator, es[4]\display_path!.text

  context 'parse', ->
    it 'jumps to root for "/"', ->
      e = DirectoryExplorer (tmp_root .. 'sub/')
      assert.same {File '/'}, [explorer.file for explorer in *e\parse('/').jump_to_absolute]

    it 'returns a new absolute list of explorers', ->
      e = DirectoryExplorer tmp_root, root: tmp_root
      assert.same {tmp_root, subdir1}, [explorer.file for explorer in *e\parse('subdir1/').jump_to_absolute]

    it 'jumps to absolute path for "/path"', ->
      e = DirectoryExplorer subdir1
      explorers = e\parse(subdir2.path .. '/').jump_to_absolute
      assert.same subdir2.path, explorers[#explorers].file.path

  context 'listing', ->
    it 'lists all files and directories including current directory', ->
      e = DirectoryExplorer tmp_root
      assert.same {'./', 'file1', 'file2', 'subdir1/', 'subdir2/'}, items e

    context 'files_only = true', ->
      it 'shows files and directories but not current directory', ->
        -- This is to let user pick a file from a different directory
        e = DirectoryExplorer tmp_root, files_only: true
        assert.same {'file1', 'file2', 'subdir1/', 'subdir2/'}, items e

    context 'directories_only = true', ->
      it 'shows directories including current directory', ->
        e = DirectoryExplorer tmp_root, directories_only: true
        assert.same {'./', 'subdir1/', 'subdir2/'}, items e

    context 'recursive listing', ->
      it 'shows contents of entire subtree', ->
        e = DirectoryExplorer tmp_root
        e\actions!.toggle_subtree.handler e
        contents = {
          './', 'file1', 'file2', 'subdir1/', 'subdir1/file3', 'subdir2/'
        }
        assert.same contents, items e

      it 'changing recursive mode updates all explorers in path', ->
        (subdir1 .. 'a/b')\mkdir_p!
        explorers = DirectoryExplorer.for_path subdir1.path, root: tmp_root
        inner = explorers[2]
        outer = explorers[1]

        inner\actions!.toggle_subtree.handler inner
        -- both should switch to recursive mode
        assert.same 4, #items inner
        assert.same 8, #items outer

        inner\actions!.toggle_subtree.handler inner
        -- both should also switch back to non-recursive mode
        assert.same 3, #items inner
        assert.same 5, #items outer


