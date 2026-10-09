-- Copyright 2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import icon, style from howl.ui
require 'howl.ui.icons.nerd_fonts'

describe 'nerd_fonts icons', ->
  built_in_icons = {
    'nerd-cod-folder'
    'nerd-cod-file'
    'nerd-cod-new-file'
    'nerd-cod-target'
    'nerd-cod-symbol-interface'
    'nerd-cod-symbol-class'
    'nerd-cod-type-hierarchy-sub'
    'nerd-cod-references'
    'nerd-cod-info'
    'nerd-cod-record-keys'
    'nerd-cod-circle-filled'
    'nerd-cod-sync'
    'nerd-cod-pass'
    'nerd-cod-play-circle'
    'nerd-cod-error'
  }

  it 'defines the internally used glyphs as nerd- icons', ->
    for name in *built_in_icons
      assert.is_not_nil icon.get name

  it 'defines Font Awesome glyphs as nerd-<name>', ->
    assert.equal '\u{f07b}', icon.get('nerd-folder').text

  it 'defines Codicon glyphs as nerd-cod-<name>, with dashes in the names', ->
    assert.equal '\u{eb36}', icon.get('nerd-cod-references').text
    assert.equal '\u{ea8c}', icon.get('nerd-cod-symbol-method').text

  it 'renders icons with the Symbols Nerd Font family', ->
    for name in *{'nerd-folder', 'nerd-cod-folder'}
      styled = icon.get name
      base_style = styled.styles[2]\match '[^:]+'
      assert.same 'Symbols Nerd Font', style[base_style].font.family
