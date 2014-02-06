core = require 'ljglibs.core'
require 'ljglibs.cdefs.gtk'

core.auto_loading 'gtk', {
  constants: {
    prefix: 'GTK_'

    -- GtkStateFlags
    'STATE_FLAG_NORMAL',
    'STATE_FLAG_ACTIVE',
    'STATE_FLAG_PRELIGHT',
    'STATE_FLAG_SELECTED',
    'STATE_FLAG_INSENSITIVE',
    'STATE_FLAG_INCONSISTENT',
    'STATE_FLAG_FOCUSED',

    -- GtkPositionType
    'POS_LEFT',
    'POS_RIGHT',
    'POS_TOP',
    'POS_BOTTOM'

    -- GtkOrientation
    'ORIENTATION_HORIZONTAL',
    'ORIENTATION_VERTICAL',

    -- GtkPackType
    'PACK_START',
    'PACK_END'

    -- GtkJustification
    'JUSTIFY_LEFT'
    'JUSTIFY_RIGHT'
    'JUSTIFY_CENTER'
    'JUSTIFY_FILL'

    -- GtkWindowPosition;
    'WIN_POS_NONE'
    'WIN_POS_CENTER'
    'WIN_POS_MOUSE'
    'WIN_POS_CENTER_ALWAYS'
    'WIN_POS_CENTER_ON_PARENT'
  }
}
