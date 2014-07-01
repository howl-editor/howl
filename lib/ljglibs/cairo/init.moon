-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE.md)
core = require 'ljglibs.core'

require 'ljglibs.cdefs.cairo'
ffi = require 'ffi'
C, ffi_string, ffi_gc, ffi_new = ffi.C, ffi.string, ffi.gc, ffi.new

core.auto_loading 'cairo', {
}
