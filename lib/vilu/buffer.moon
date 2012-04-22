import PropertyObject from vilu.aux.moon
import Delegator from vilu.aux.moon
import GtkSource from lgi

class Buffer extends Delegator
  new: (style_scheme) =>
    @buf = GtkSource.Buffer :style_scheme
    getmetatable(self).__to_gobject = => @buf
    super @buf

return Buffer
