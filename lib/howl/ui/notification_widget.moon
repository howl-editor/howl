-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import TextWidget from howl.ui

class NotificationWidget
  new: (...) => @swidget = TextWidget ...

  caption: (text) => @notify nil, text

  info: (text) => @notify 'info', text

  warning: (text) => @notify 'warning', text

  error: (text) => @notify 'error', text

  clear: => @swidget.text = ''

  notify: (level, text) =>
    @\clear!
    @swidget.buffer\append text, level and 'status-'..level
    @swidget.height_rows = #@swidget.buffer.lines

  hide: => @swidget\hide!

  show: => @swidget\show!

  to_gobject: => @swidget\to_gobject!

return NotificationWidget
