-- Copyright 2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

{:define_class} = require 'aullar.util'
{:insert, :remove} = table

selector_matches = (selector, marker) ->
  return true unless selector

  for k, v in pairs selector
    return false unless marker[k] == v

  true

define_class {
  new: (@listener) =>
    @markers = {}

  add: (markers) =>
    for marker in *markers
      for f in *{ 'name', 'start_offset', 'end_offset' }
        error "Missing field '#{f}'", 2 unless marker[f]

      idx = #@markers + 1
      for i = 1, #@markers
        m = @markers[i]
        if m.start_offset > marker.start_offset
          idx = i
          break

      insert @markers, idx, marker

    @_notify 'added', markers

  remove: (selector = {}) =>
    indices = {}
    markers = {}

    for i = 1, #@markers
      marker = @markers[i]
      if selector_matches(selector, marker)
        insert(indices, i)
        insert markers, marker

    return if #markers == 0

    for i = #indices, 1, -1
      remove @markers, indices[i]

    @_notify 'removed', markers

  remove_for_range: (start_offset, end_offset, selector) =>
    _, indices = @_scan start_offset, end_offset, selector
    markers = {}

    for i = #indices, 1, -1
      insert markers, (remove @markers, indices[i])

    return if #markers == 0
    @_notify 'removed', markers

  at: (offset, selector) =>
    @for_range offset, offset + 1, selector

  for_range: (start_offset, end_offset, selector) =>
    (@_scan start_offset, end_offset, selector)

  find: (selector) =>
    [m for m in *@markers when selector_matches(selector, m)]

  expand: (offset, count) =>
    for i = 1, #@markers
      m = @markers[i]
      if m.start_offset >= offset -- after expansion
        m.start_offset += count
        m.end_offset += count
      elseif m.start_offset < offset and m.end_offset > offset -- enclosing
        m.end_offset += count

  shrink: (offset, count) =>
    to_remove = {}
    end_offset = offset + count

    for i = 1, #@markers
      m = @markers[i]
      continue if m.end_offset <= offset -- before expansion
      if m.start_offset >= end_offset -- after expansion
        m.start_offset -= count
        m.end_offset -= count
      elseif m.start_offset <= offset and m.end_offset >= end_offset -- enclosing
        m.end_offset -= count
      else -- otherwise affected, remove it
        insert to_remove, i

    for i = #to_remove, 1, -1
      remove @markers, to_remove[i]

  _scan: (start_offset, end_offset, selector) =>
    found = {}
    indices = {}
    for i = 1, #@markers
      m = @markers[i]
      break if end_offset < m.start_offset
      if m.end_offset > start_offset and m.start_offset < end_offset
        if not selector or selector_matches(selector, m)
          insert found, m
          insert indices, i

    found, indices

  _notify: (what, markers) =>
    if @listener and #markers > 0
      handler = @listener["on_markers_#{what}"]
      handler(@listener, markers) if handler

 }
