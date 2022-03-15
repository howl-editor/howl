core = require 'ljglibs.core'
require 'ljglibs.gtk.event_controller'

{:C} = require 'ffi'

core.define 'GtkEventControllerFocus < GtkEventController', {
    properties: {
      contains_focus: 'gboolean'
      is_focus: 'gboolean'
    }

}, (t) -> C.gtk_event_controller_focus_new!
