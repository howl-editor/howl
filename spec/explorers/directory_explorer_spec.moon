require 'howl.ui.icons.font_awesome'  -- icons required by DirectoryExplorer
{:DirectoryExplorer} = howl.explorers
{:File} = howl.io

describe 'DirectoryExplorer', ->
  local tmp_root, subdir1, subdir2
  before_each ->
    tmp_root = File.tmpdir!
    subdir1 = tmp_root .. 'subdir1/'
    subdir1\mkdir!
    subdir2 = tmp_root .. 'subdir2/'
    subdir2\mkdir!

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
