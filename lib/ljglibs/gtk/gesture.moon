core = require 'ljglibs.core'
require 'ljglibs.gtk.event_controller'

core.define 'GtkGesture < GtkEventController', {
  properties: {
    n_points: 'guint'
  }
}
