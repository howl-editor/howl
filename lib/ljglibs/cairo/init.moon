-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)
core = require 'ljglibs.core'

require 'ljglibs.cdefs.cairo'
ffi = require 'ffi'
C, ffi_string, ffi_gc, ffi_new = ffi.C, ffi.string, ffi.gc, ffi.new

core.auto_loading 'cairo', {
}
