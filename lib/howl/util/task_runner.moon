-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import dispatch, timer from howl

append = table.insert

class TaskRunner
  new: =>
    @pending = {}
    @running = nil

  run: (name, f) =>
    append @pending, { :name, handler: f }
    if not @running
      @_run_next!

  _run_next: =>
    if @running
      error '_run_next called while another task running'

    next = table.remove @pending, 1
    if next
      @_run next
    else
      if self.finish_function
        self.finish_function!

  _run: (task) =>
    dispatch.launch ->
      @running = task.name
      ok, err = pcall -> task.handler @\_yield
      @running = nil

      if not ok
        error err

      @_run_next!

  _yield: =>
    @parked = dispatch.park 'TaskRunner'

    timer.asap ->
      if @running and @parked
        dispatch.resume @parked, false

    result = dispatch.wait @parked
    @parked = nil
    return result

  cancel: (name) =>
    for i = #@pending, 1, -1
      if @pending[i].name == name
        table.remove @pending, i

    if @running == name
      @running = nil
      if @parked
        dispatch.resume @parked, true

  cancel_all: =>
    @pending = {}

    if @running
      @running = nil
      if @parked
        dispatch.resume @parked, true

return TaskRunner
