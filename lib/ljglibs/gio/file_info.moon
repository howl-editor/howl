-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

ffi = require 'ffi'
require 'ljglibs.cdefs.gio'
core = require 'ljglibs.core'
glib = require 'ljglibs.glib'
import g_string from glib

C, ffi_string = ffi.C, ffi.string

core.define 'GFileInfo', {
  constants: {
    prefix: 'G_FILE_'

    'TYPE_UNKNOWN',
    'TYPE_REGULAR',
    'TYPE_DIRECTORY',
    'TYPE_SYMBOLIC_LINK',
    'TYPE_SPECIAL',
    'TYPE_SHORTCUT',
    'TYPE_MOUNTABLE'
  }

  properties: {
    name: => ffi_string C.g_file_info_get_name @
    is_hidden: => C.g_file_info_get_is_hidden(@) != 0
    is_backup: => C.g_file_info_get_is_backup(@) != 0
    is_symlink: => C.g_file_info_get_is_symlink(@) != 0
    filetype: => C.g_file_info_get_file_type @
    size: => tonumber C.g_file_info_get_size @
    etag: => ffi_string C.g_file_info_get_etag @
 }

  get_attribute_string: (attribute) => ffi_string C.g_file_info_get_attribute_string @, attribute
  get_attribute_boolean: (attribute) => C.g_file_info_get_attribute_boolean(@, attribute) != 0
  get_attribute_uint64: (attribute) => C.g_file_info_get_attribute_uint64 @, attribute
}
