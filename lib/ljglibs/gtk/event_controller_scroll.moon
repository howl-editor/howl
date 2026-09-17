core = require 'ljglibs.core'
require 'ljglibs.gtk.event_controller'

{:C} = require 'ffi'

core.define 'GtkEventControllerScroll < GtkEventController', {
  constants: {
    prefix: 'GTK_EVENT_CONTROLLER_SCROLL_'

    -- GtkEventControllerScrollFlags
    'NONE',
    'VERTICAL',
    'HORIZONTAL',
    'DISCRETE',
    'KINETIC',
    'BOTH_AXES'
  }

  properties: {
    flags: 'GtkEventControllerScrollFlags'
  }
}, (t, flags) -> C.gtk_event_controller_scroll_new flags
