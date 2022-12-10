core = require 'ljglibs.core'
require 'ljglibs.gobject.object'
require 'ljglibs.cdefs.gtk'

ffi = require 'ffi'
C = ffi.C

core.define 'GtkEventController < GObject', {
  properties: {
    name: 'gchar *'
    propagation_phase: 'GtkPropagationPhase'
  }

  get_current_event: =>
    C.gtk_event_controller_get_current_event @
}
