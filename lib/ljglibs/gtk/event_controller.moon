core = require 'ljglibs.core'
require 'ljglibs.gobject.object'
require 'ljglibs.cdefs.gtk'

core.define 'GtkEventController < GObject', {
  properties: {
    name: 'gchar *'
  }
}
