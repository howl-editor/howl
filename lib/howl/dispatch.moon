-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)
pack, unpack = table.pack, table.unpack

parked = {}
id_counter = 0

_resume = (handle, ...) ->
  parking = parked[handle]
  error "Unknown handle #{handle}", 3 unless parking
  ret = if parking.co
    pack coroutine.resume parking.co, ...
  else
    parking.resumer = coroutine.running!
    parking.pending = pack ...
    coroutine.yield!
    { true }

  parked[handle] = nil
  ret

{
  park: (description) ->
    id_counter += 1
    parked[id_counter] = { id: id_counter, :description }
    id_counter

  resume: (handle, ...) ->
    ret = _resume handle, true, ...
    error(ret[2], ret[3]) unless ret[1]
    unpack ret, 2, ret.n

  resume_with_error: (handle, err, level = 1) ->
    _resume handle, false, err, level

  wait: (handle) ->
    parking = parked[handle]
    error "Unknown handle #{handle}", 2 unless parking
    co, is_main = coroutine.running!
    error "Cannot invoke wait() from the main coroutine", 2 if is_main

    local ret

    if parking.resumer
      coroutine.resume parking.resumer
      ret = parking.pending
    else
      parking.co = co
      ret = pack coroutine.yield!

    error(ret[2], ret[3]) unless ret[1]
    unpack ret, 2, ret.n

  launch: (f, ...) ->
    co = coroutine.create (...) -> f ...
    status, err = coroutine.resume co, ...
    status, (status and coroutine.status(co) or err)
}
