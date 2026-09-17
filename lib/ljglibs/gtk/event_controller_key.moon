core = require 'ljglibs.core'
require 'ljglibs.gtk.event_controller'
ffi = require 'ffi'
ffi_cast = ffi.cast

{:C} = require 'ffi'

core.define 'GtkEventControllerKey < GtkEventController', {
  set_im_context: (context) =>
    context = ffi_cast('GtkIMContext *', context)
    C.gtk_event_controller_key_set_im_context @, context

}, -> C.gtk_event_controller_key_new!
