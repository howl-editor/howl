-- Copyright 2026 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

ffi = require 'ffi'
require 'ljglibs.cdefs.gtk'
require 'ljglibs.gobject.object'
require 'ljglibs.gdk.texture'
core = require 'ljglibs.core'
gobject = require 'ljglibs.gobject'
{:catch_error} = require 'ljglibs.glib'

gc_ptr = gobject.gc_ptr
C = ffi.C

core.define 'GskRenderer < GObject', {
  -- a realized software renderer for display, which needs to be unrealized
  -- before it's released
  new_cairo: (display) ->
    renderer = gc_ptr C.gsk_cairo_renderer_new!
    catch_error C.gsk_renderer_realize_for_display, renderer, display
    renderer

  -- renders node into a new texture, which is the size of the viewport
  render_texture: (node, x, y, width, height) =>
    viewport = ffi.new 'graphene_rect_t', { { x, y }, { width, height } }
    gc_ptr C.gsk_renderer_render_texture(@, node, viewport)

  unrealize: => C.gsk_renderer_unrealize @
}
