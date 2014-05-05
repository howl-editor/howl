core = require 'ljglibs.core'
callbacks = require 'ljglibs.callbacks'
ffi = require 'ffi'

core.auto_loading 'gio', {
  async_ready_callback: ffi.cast('GVCallback3', callbacks.void3)
}
