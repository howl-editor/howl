-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE.md)

core = require 'ljglibs.core'
require 'ljglibs.cdefs.pango'

core.auto_loading 'pango', {
  constants: {
    prefix: 'PANGO_'
    'ALIGN_LEFT',
    'ALIGN_CENTER',
    'ALIGN_RIGHT',
  }
}
