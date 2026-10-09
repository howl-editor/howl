{:TextWidget} = howl.ui

describe 'TextWidget', ->
  it 'opts.tab_size sets the width of a tab, in spaces', ->
    assert.equals 2, TextWidget(tab_size: 2).view.config.view_tab_size

  context 'resource management', ->

    it 'widgets are collected as they should', ->
      w = TextWidget!
      list = setmetatable {w}, __mode: 'v'
      w = nil
      collectgarbage!
      assert.is_true list[1] == nil
