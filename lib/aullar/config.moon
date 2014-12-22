-- Copyright 2012-2014 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

GtkSettings = require 'ljglibs.gtk.settings'
Pango = require 'ljglibs.pango'

define_options = ->
  settings = GtkSettings.get_default!
  gtk_font = Pango.FontDescription.from_string settings.gtk_font_name

  {
    tab_width: {
      type: 'number',
      default: 4
    },

    font_name: {
      type: 'string',
      default: 'Monospace'

    },

    font_size: {
      type: 'number',
      default: gtk_font.size / Pango.SCALE
    }
  }

values = {}
defs = define_options!
listeners = {}


setmetatable {
  add_listener: (listener) ->
    listeners[#listeners + 1] = listener

  remove_listener: (listener) ->
    listeners = [l for l in *listeners when l != listener]

}, {
  __index: (t, k) ->
    v = values[k]
    return v if v
    def = defs[k]
    error("Invalid option '#{k}'", 2) unless def
    def.default

  __newindex: (t, k, v) ->
    old_v = t[k]
    values[k] = v
    for l in *listeners
      status, ret = pcall l, k, v, old_v
      unless status
        print "Error invoking listener for change (#{k}: #{old_v} -> #{v})"
}
