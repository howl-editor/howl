-- Copyright 2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import icon, style from howl.ui
require 'howl.ui.icons.nerd_fonts'

describe 'nerd_fonts icons', ->
  built_in_icons = {
    'nerd-folder'
    'nerd-file'
    'nerd-plus-circle'
    'nerd-crosshairs'
    'nerd-bookmark-o'
    'nerd-cube'
    'nerd-cogs'
    'nerd-link'
    'nerd-info'
    'nerd-keyboard-o'
    'nerd-square'
    'nerd-pencil-square-o'
    'nerd-clone'
    'nerd-check-circle'
    'nerd-play-circle'
    'nerd-exclamation-circle'
  }

  it 'defines the internally used glyphs as nerd- icons', ->
    for name in *built_in_icons
      assert.is_not_nil icon.get name

  it 'renders icons with the Symbols Nerd Font family', ->
    styled = icon.get 'nerd-folder'
    base_style = styled.styles[2]\match '[^:]+'
    assert.same 'Symbols Nerd Font', style[base_style].font.family
