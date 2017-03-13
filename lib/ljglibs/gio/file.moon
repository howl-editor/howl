-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

ffi = require 'ffi'
require 'ljglibs.cdefs.gio'
require 'ljglibs.gio.file_info'
require 'ljglibs.gio.file_input_stream'
require 'ljglibs.gio.file_output_stream'
core = require 'ljglibs.core'
glib = require 'ljglibs.glib'
callbacks = require 'ljglibs.callbacks'
import gc_ptr from require 'ljglibs.gobject'
import g_string, catch_error from glib

C = ffi.C

core.define 'GFileEnumerator', {
  next_file: => gc_ptr catch_error C.g_file_enumerator_next_file, @, nil
  close: => catch_error C.g_file_enumerator_close, @, nil
}

core.define 'GFile', {
  constants: {
    prefix: 'G_FILE_'

    'QUERY_INFO_NONE',
    'QUERY_INFO_NOFOLLOW_SYMLINKS',

    'COPY_NONE',
    'COPY_OVERWRITE',
    'COPY_BACKUP',
    'COPY_NOFOLLOW_SYMLINKS',
    'COPY_ALL_METADATA',
    'COPY_NO_FALLBACK_FOR_MOVE',
    'COPY_TARGET_DEFAULT_PERMS',
  }

  new_for_path: (p) -> gc_ptr C.g_file_new_for_path p

  new_for_commandline_arg_and_cwd: (p, cwd) ->
    assert glib.check_version 2, 36, 0
    gc_ptr C.g_file_new_for_commandline_arg_and_cwd p, cwd

  get_relative_path: (parent, descendant) ->
    g_string C.g_file_get_relative_path parent, descendant

  properties: {
    path: => g_string C.g_file_get_path @
    uri: => g_string C.g_file_get_uri @
    exists: => C.g_file_query_exists(@, nil) != 0
    parent: => gc_ptr C.g_file_get_parent @
    basename: => g_string C.g_file_get_basename @
  }

  has_parent: (parent = nil) => C.g_file_has_parent(@, parent) != 0
  query_info: (attributes, flags) =>
    gc_ptr catch_error C.g_file_query_info, @, attributes, flags, nil

  load_contents: =>
    buf = ffi.new 'char *[1]'
    catch_error C.g_file_load_contents, @, nil, buf, nil, nil
    g_string buf[0]

  get_child: (name) => gc_ptr C.g_file_get_child @, name

  enumerate_children: (attributes, flags = @QUERY_INFO_NONE) =>
    gc_ptr catch_error C.g_file_enumerate_children, @, attributes, flags, nil

  copy: (dest, flags, cancellable, callback) =>
    self = @
    local cb_handle

    handler = (current_bytes, total_bytes) ->
      callback self, current_bytes, total_bytes

    cb_handle = callbacks.register handler, 'file-progress'
    cb_cast = ffi.cast('GFileProgressCallback', callbacks.void3)
    catch_error(C.g_file_copy, @, dest, flags, cancellable, cb_cast, callbacks.cast_arg(cb_handle.id)) != 0

  make_directory: => catch_error(C.g_file_make_directory, @, nil) != 0
  make_directory_with_parents: => catch_error(C.g_file_make_directory_with_parents, @, nil) != 0
  delete: => catch_error(C.g_file_delete, @, nil) != 0

  read: => gc_ptr catch_error(C.g_file_read, @, nil)
  append_to: => gc_ptr catch_error(C.g_file_append_to, @, 0, nil)

  meta: {
    __tostring: (f) -> f.path
  }
}, (def, p) -> def.new_for_path p
