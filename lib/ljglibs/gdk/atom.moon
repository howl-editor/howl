-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

ffi = require 'ffi'
require 'ljglibs.cdefs.gdk'
core = require 'ljglibs.core'
glib = require 'ljglibs.glib'

C = ffi.C

AtomStruct = ffi.typeof('GdkAtom')

def = {
  properties: {
    name: => glib.g_string C.gdk_atom_name(@)
  }

  intern: (name, only_if_exists = false) ->
    C.gdk_atom_intern(name, only_if_exists)

  from_value: (value) ->
    AtomStruct(value)

}

for name, value in pairs {
  SELECTION_PRIMARY: 1,
  SELECTION_SECONDARY: 2,
  SELECTION_CLIPBOARD: 69,
}
  def[name] = def.from_value value

core.define 'GdkAtom', def, (t, name) -> t.intern(name)
