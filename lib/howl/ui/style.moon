-- Copyright 2012-2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import colors from howl.ui
aullar_styles = require 'aullar.styles'
{:define, :define_default} = aullar_styles

set_for_theme = (theme) ->
  for name, definition in pairs theme.styles
    define name, definition

at_pos = (buffer, pos) ->
  b_pos = buffer\byte_offset pos
  buffer._buffer.styling\at b_pos

-- define some default styles
define 'black', color: colors.black
define 'red', color: colors.red
define 'green', color: colors.green
define 'yellow', color: colors.yellow
define 'blue', color: colors.blue
define 'magenta', color: colors.magenta
define 'cyan', color: colors.cyan
define 'white', color: colors.white

-- alias some default styles
define 'symbol', 'key'
define 'global', 'member'
define 'regex', 'string'
define 'type_def', 'type'

return setmetatable {
  :set_for_theme
  :define
  :define_default
  :at_pos
}, __index: (t, k) ->
  aullar_styles.def_for k
