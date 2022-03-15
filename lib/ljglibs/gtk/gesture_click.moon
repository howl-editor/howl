core = require 'ljglibs.core'
require 'ljglibs.gtk.gesture_single'

{:C} = require 'ffi'

core.define 'GtkGestureClick < GtkGestureSingle', {
}, (t) -> C.gtk_gesture_click_new!
