core = require 'ljglibs.core'
require 'ljglibs.gtk.event_controller'

{:C} = require 'ffi'

core.define 'GtkEventControllerMotion < GtkEventController', {
    properties: {
      contains_pointer: 'gboolean'
      is_pointer: 'gboolean'
    }
}, (t) -> C.gtk_event_controller_motion_new!
