-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

ffi = require 'ffi'
{:catch_error, :char_p_arr} = require 'ljglibs.glib'
core = require 'ljglibs.core'
require 'ljglibs.gobject.object'
require 'ljglibs.cdefs.gdk'

{:C, :gc} = ffi

core.define 'GdkPixbuf < GObject', {
  properties: {
    width: 'gint'
    height: 'gint'
    bits_per_sample: 'gint'
    n_channels: 'gint'
    rowstride: 'gint'
    has_alpha: 'gboolean'
  }

  new_from_file: (filename) ->
    pb = catch_error(C.gdk_pixbuf_new_from_file, filename)
    return nil if pb == nil
    gc pb, C.g_object_unref

  new_from_file_at_size: (filename, width, height) ->
    pb = catch_error(C.gdk_pixbuf_new_from_file_at_size, filename, width, height)
    return nil if pb == nil
    gc pb, C.g_object_unref

  new_from_file_at_scale: (filename, width, height, preserve_aspect_ratio) ->
    pb = catch_error(C.gdk_pixbuf_new_from_file_at_scale, filename, width, height, preserve_aspect_ratio)
    return nil if pb == nil
    gc pb, C.g_object_unref

  get_from_window: (window, x, y, width, height) ->
    pixbuf = C.gdk_pixbuf_get_from_window(window, x, y, width, height)
    error 'Failed to get pixbuf' unless pixbuf
    gc(pixbuf, C.g_object_unref)
    pixbuf

  scale_simple: (dest_width, dest_height, interp_type) =>
    pixbuf = C.gdk_pixbuf_scale_simple @, dest_width, dest_height, interp_type
    error 'Failed to scale pixbuf' unless pixbuf
    gc(pixbuf, C.g_object_unref)
    pixbuf

  save: (filename, type, opts={}) =>
    opts_pairs = [{:key, :value} for key, value in pairs opts]
    option_keys = char_p_arr [item.key for item in *opts_pairs]
    option_values = char_p_arr [item.value for item in *opts_pairs]
    catch_error(C.gdk_pixbuf_savev, @, filename, type, option_keys, option_values)
}, nil
