-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

{:define_class} = require 'aullar.util'

coalesce = (entry, prev) ->
  return false if not prev
  if entry.type == 'inserted' and prev.type == 'inserted'
    if entry.offset == prev.offset + #prev.text
      prev.text ..= entry.text
      return true

  elseif entry.type == 'deleted' and prev.type == 'deleted'
    if prev.offset == entry.offset + #entry.text
      prev.text = entry.text .. prev.text
      prev.offset = entry.offset
      return true
    elseif prev.offset == entry.offset
      prev.text ..= entry.text
      return true

  false

VALID_TYPES = {t,true for t in *{'inserted', 'deleted', 'changed'}}

define_class {
  new: =>
    @clear!
    @processing = false

  properties: {
    last: => @entries[@current]
  }

  push: (type, offset, text, prev_text = nil, meta = {}) =>
    unless VALID_TYPES[type]
      error "Unknown revision type '#{type}'", 2

    return if @processing
    group = @grouping > 0 and @group_id or nil
    entry =  :type, :offset, :text, :prev_text, :meta, :group
    last = @last
    if last and entry.group == last.group
      return last if coalesce(entry, last)

    @current += 1
    @entries[@current] = entry

    -- reset any outstanding forward revisions
    for i = @current + 1, #@entries
      @entries[i] = nil

    entry

  pop: (buffer) =>
    entry = @entries[@current]
    return unless entry
    @processing = true

    if entry.type == 'inserted'
      buffer\delete entry.offset, #entry.text
    elseif entry.type == 'deleted'
      buffer\insert entry.offset, entry.text
    elseif entry.type == 'changed'
      buffer\delete entry.offset, #entry.text
      buffer\insert entry.offset, entry.prev_text

    @current -= 1
    @processing = false

    if entry.group and @last and @last.group == entry.group
      return @pop(buffer)

    entry

  forward: (buffer) =>
    entry = @entries[@current + 1]
    return unless entry
    @processing = true

    if entry.type == 'inserted'
      buffer\insert entry.offset, entry.text
    elseif entry.type == 'deleted'
      buffer\delete entry.offset, #entry.text
    elseif entry.type == 'changed'
      buffer\delete entry.offset, #entry.prev_text
      buffer\insert entry.offset, entry.text

    @current += 1
    @processing = false

    next = @entries[@current + 1]
    if entry.group and next and next.group == entry.group
      return @forward(buffer)

    entry

  clear: =>
    @entries = {}
    @popped_entries = nil
    @grouping = 0
    @group_id = 0
    @current = 0

  start_group: =>
    @group_id += 1 if @grouping == 0
    @grouping += 1

  end_group: =>
    @grouping -= 1

}, {
  __index: (k) =>
    return @entries[k] if type(k) == 'number'

  __len: => @current
}
