core = require 'ljglibs.core'
require 'ljglibs.gtk.gesture'

ffi = require 'ffi'
C = ffi.C

core.define 'GtkGestureSingle < GtkGesture', {
  properties: {
    button: 'guint'
  }

  get_current_button: =>
    tonumber C.gtk_gesture_single_get_current_button @

}
