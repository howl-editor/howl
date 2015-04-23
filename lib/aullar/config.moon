-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

GtkSettings = require 'ljglibs.gtk.settings'
Pango = require 'ljglibs.pango'

define_options = ->
  settings = GtkSettings.get_default!
  gtk_font = Pango.FontDescription.from_string settings.gtk_font_name

  {
    view_tab_size: {
      type: 'number',
      default: 4
    },

    view_font_name: {
      type: 'string',
      default: 'Monospace'
    },

    view_indent: {
      type: 'number',
      default: 2
    },

    view_font_size: {
      type: 'number',
      default: gtk_font.size / Pango.SCALE
    },

    view_show_line_numbers: {
      type: 'boolean',
      default: true
    },

    view_show_indentation_guides: {
      type: 'boolean',
      default: false
    },

    view_edge_column: {
      type: 'number',
      default: nil
    },

    view_show_h_scrollbar: {
      type: 'boolean',
      default: true
    },

    view_show_v_scrollbar: {
      type: 'boolean',
      default: true
    },

    view_show_cursor: {
      type: 'boolean',
      default: true
    },

    view_highlight_current_line: {
      type: 'boolean',
      default: true
    },

  }

notify_listeners = (listeners, k, new_v, old_v) ->
  for l in *listeners
    status, ret = pcall l, k, new_v, old_v
    unless status
      io.stderr\write "Error invoking listener for change (#{k}: #{old_v} -> #{new_v}): #{ret}\n"

get_value = (k, values, defs) ->
  v = values[k]
  return v if v
  def = defs[k]
  error("Invalid option '#{k}'", 3) unless def
  def.default

set_value = (t, k, v, values, defs, listeners) ->
  def = defs[k]
  error("Invalid option '#{k}'", 3) unless def
  new_t = type v
  if v != nil and def.type and def.type != new_t
    error "Illegal type '#{new_t}' for #{k}", 3

  old_v = t[k]
  values[k] = v
  new_v = t[k]

  if new_v != old_v
    notify_listeners listeners, k, new_v, old_v

  new_v, old_v

add_listener = (listener, listeners) ->
  listeners[#listeners + 1] = listener

remove_listener = (listener, listeners) ->
  [l for l in *listeners when l != listener]

values = {}
defs = define_options!
listeners = {}
proxies = {}

setmetatable {
  add_listener: (listener) -> add_listener listener, listeners
  remove_listener: (listener) -> listeners = remove_listener listener, listeners
  definition_for: (option) -> defs[option]

  local_proxy: ->
    proxy = setmetatable {
      values: {},
      listeners: {}

      add_listener: (listener) =>
        add_listener listener, @listeners

      remove_listener: (listener) =>
        @listeners = remove_listener listener, @listeners

      detach: =>
        proxies = [p for p in *proxies when p != @]

     }, {
      __index: (k) =>
        v = @values[k]
        return v if v != nil
        get_value(k, values, defs)

      __newindex: (k, v) =>
        set_value @, k, v, @values, defs, @listeners
    }
    proxies[#proxies + 1] = proxy
    proxy

}, {
  __index: (t, k) -> get_value k, values, defs
  __newindex: (t, k, v) ->
    new_v, old_v = set_value t, k, v, values, defs, listeners
    return if new_v == old_v

    -- bubble up notification to local proxies
    for proxy in *proxies
      if proxy.values[k] == nil -- no local value set
        notify_listeners proxy.listeners, k, new_v, old_v
}
