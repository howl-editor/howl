-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)
pack, unpack = table.pack, table.unpack

parked = {}
id_counter = 0

get_parking = (handle) ->
  parking = parked[handle]
  error "Unknown handle #{handle}", 3 unless parking
  error "Nothing waiting on #{handle}", 3 unless parking.co
  parked[handle] = nil
  parking

{
  park: (description) ->
    id_counter += 1
    parked[id_counter] = { id: id_counter, :description }
    id_counter

  resume: (handle, ...) ->
    coroutine.resume get_parking(handle).co, true, ...

  resume_with_error: (handle, err, level) ->
    coroutine.resume get_parking(handle).co, false, err, level

  wait: (handle) ->
    parking = parked[handle]
    error "Unknown handle #{handle}", 2 unless parking
    co, is_main = coroutine.running!
    error "Cannot invoke wait() from the main coroutine", 2 if is_main
    parking.co = co
    ret = pack coroutine.yield!
    error(ret[2], ret[3]) unless ret[1]
    unpack ret, 2, ret.n

  launch: (f, ...) ->
    co = coroutine.create (...) -> f ...
    status, err = coroutine.resume co, ...
    status, status and coroutine.status(co) or err
}
