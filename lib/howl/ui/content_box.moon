-- Copyright 2015-2023 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

Gtk = require 'ljglibs.gtk'

class ContentBox

  new: (@name, @content_widget, opts = {})=>
    @opts = opts

    @widget = Gtk.Box Gtk.ORIENTATION_VERTICAL
    @widget.css_classes = {'content-box', "content-box-#{name}"}

    if opts.header
      @widget\append opts.header

    @widget\append content_widget

    if opts.footer
      @widget\append opts.footer

  to_gobject: => @widget
