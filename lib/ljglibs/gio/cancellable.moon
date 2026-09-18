-- Copyright 2026 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

-- GCancellable is declared as `typedef void GCancellable` in ljglibs/cdefs/gio.moon,
-- and every gio cdef in the tree references it that way. It therefore cannot be
-- given an ffi.metatype, which rules out core.define - hence this plain module of
-- free functions rather than a class.
--
-- This is what makes a real timeout possible: without a cancellable there is no
-- way to abort an outstanding async read, and "timing out" by resuming the parked
-- coroutine from a timer leaves the read callback to fire later and resume a
-- handle that is no longer parked, raising from inside an FFI callback.

ffi = require 'ffi'
require 'ljglibs.cdefs.gio'

C = ffi.C

{
  create: -> ffi.gc C.g_cancellable_new!, C.g_object_unref

  cancel: (cancellable) ->
    C.g_cancellable_cancel cancellable if cancellable != nil

  is_cancelled: (cancellable) ->
    cancellable != nil and C.g_cancellable_is_cancelled(cancellable) != 0

  reset: (cancellable) ->
    C.g_cancellable_reset cancellable if cancellable != nil
}
