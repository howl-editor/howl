-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE.md)
core = require 'ljglibs.core'

require 'ljglibs.cdefs.pango'
ffi = require 'ffi'
C = ffi.C

constants = {
  'ALIGN_LEFT',
  'ALIGN_CENTER',
  'ALIGN_RIGHT',
}

def = {}

for constant in *constants
  def[constant] = C["PANGO_#{constant}"]

core.auto_loading 'pango', def
