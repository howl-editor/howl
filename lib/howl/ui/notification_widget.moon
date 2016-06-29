-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import TextWidget from howl.ui

class NotificationWidget
  new: (...) => @text_widget = TextWidget ...

  caption: (text) => @notify nil, text

  info: (text) => @notify 'info', text

  warning: (text) => @notify 'warning', text

  error: (text) => @notify 'error', text

  clear: => @text_widget.text = ''

  notify: (style, text) =>
    @clear!
    @text_widget.buffer\append text, style
    @text_widget.visible_rows = #@text_widget.buffer.lines

  hide: => @text_widget\hide!

  show: => @text_widget\show!

  to_gobject: => @text_widget\to_gobject!

return NotificationWidget
