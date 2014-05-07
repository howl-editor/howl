-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

ffi = require 'ffi'
jit = require 'jit'
require 'ljglibs.cdefs.gtk'
core = require 'ljglibs.core'
gobject = require 'ljglibs.gobject'
require 'ljglibs.gtk.widget'

gc_ptr = gobject.gc_ptr
C = ffi.C

jit.off true, true

core.define 'GtkEntry < GtkWidget', {
  properties: {
    activates_default: 'gboolean'
    buffer: 'GtkEntryBuffer*'
    caps_lock_warning: 'gboolean'
    completion: 'GtkEntryCompletion*'
    cursor_position: 'gint'
    editable: 'gboolean'
    has_frame: 'gboolean'
    im_module: 'gchar*'
    inner_border: 'GtkBorder*'
    invisible_char: 'guint'
    invisible_char_set: 'gboolean'
    max_length: 'gint'
    overwrite_mode: 'gboolean'
    placeholder_text: 'gchar*'
    primary_icon_activatable: 'gboolean'
    primary_icon_gicon: 'GIcon*'
    primary_icon_name: 'gchar*'
    primary_icon_pixbuf: 'GdkPixbuf*'
    primary_icon_sensitive: 'gboolean'
    primary_icon_stock: 'gchar*'
    primary_icon_storage_type: 'GtkImageType'
    primary_icon_tooltip_markup: 'gchar*'
    primary_icon_tooltip_text: 'gchar*'
    progress_fraction: 'gdouble'
    progress_pulse_step: 'gdouble'
    scroll_offset: 'gint'
    secondary_icon_activatable: 'gboolean'
    secondary_icon_gicon: 'GIcon*'
    secondary_icon_name: 'gchar*'
    secondary_icon_pixbuf: 'GdkPixbuf*'
    secondary_icon_sensitive: 'gboolean'
    secondary_icon_stock: 'gchar*'
    secondary_icon_storage_type: 'GtkImageType'
    secondary_icon_tooltip_markup: 'gchar*'
    secondary_icon_tooltip_text: 'gchar*'
    selection_bound: 'gint'
    shadow_type: 'GtkShadowType'
    text: 'gchar*'
    text_length: 'guint'
    truncate_multiline: 'gboolean'
    visibility: 'gboolean'
    width_chars: 'gint'
    xalign: 'gfloat'
  }

  new: ->
    gc_ptr C.gtk_entry_new!

}, (spec) -> spec.new!
