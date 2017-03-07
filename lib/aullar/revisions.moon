-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

{:define_class} = require 'aullar.util'
config = require 'aullar.config'
{:remove} = table
{:max} = math

coalesce = (entry, prev) ->
  return false if not prev or prev.dont_merge
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
    @_revision_id = 0

  properties: {
    last: => @entries[@current]
    revision_id: => @last and @last.revision_id or 0
  }

  push: (type, offset, text, opts = {}) =>
    unless VALID_TYPES[type]
      error "Unknown revision type '#{type}'", 2

    return if @processing
    group = @grouping > 0 and @group_id or nil
    entry =  {
      :type,
      :offset,
      :text,
      prev_text: opts.prev_text,
      meta: opts.meta or {},
      :group
    }
    last = @last
    if last and entry.group == last.group
      return last if coalesce(entry, last)

    @current += 1
    @_revision_id += 1
    entry.revision_id = @_revision_id
    @entries[@current] = entry

    -- reset any outstanding forward revisions
    for i = @current + 1, #@entries
      @entries[i] = nil

    unless group
      @count += 1
      @_prune!

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
    else
      @count -= 1

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
    else
      @count += 1

    entry

  clear: =>
    @entries = {}
    @grouping = 0
    @group_id = 0
    @current = 0
    @count = 0

  start_group: =>
    @group_id += 1 if @grouping == 0
    @grouping += 1

  end_group: =>
    @grouping -= 1
    if @grouping == 0
      if @current > 0 and @entries[@current].group == @group_id
        @count += 1
        @_prune!

  _prune: =>
    limit = config.undo_limit
    while @count > max limit, 1
      idx = 1 -- remove this many entries
      rev = @entries[idx]
      if rev.group -- but if grouped, remove the entire group
        while true
          next = @entries[idx + 1]
          break if not next or next.group != rev.group
          idx += 1
          rev = next

      for _ = 1, idx
        remove @entries, 1
        @current -= 1

      @count -= 1

}, {
  __len: => @count
}
