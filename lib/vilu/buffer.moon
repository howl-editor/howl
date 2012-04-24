import PropertyObject from vilu.aux.moon
import Delegator from vilu.aux.moon
import GtkSource from lgi

class Buffer extends PropertyObject
  new: (style_scheme) =>
    super!
    @sbuf = GtkSource.Buffer :style_scheme
    @mode = {}
    getmetatable(self).__to_gobject = => @sbuf

return Buffer
