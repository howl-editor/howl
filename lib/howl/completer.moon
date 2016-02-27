-- Copyright 2012-2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import completion, config from howl
append = table.insert

load_completers = (buffer, context, mode = {}) ->
  completers = {}

  for factories in *{buffer.completers, mode.completers}
    if factories
      for f in *factories
        if type(f) == 'string'
          completer = completion[f]
          f = completer and completer.factory

        error "`nil` completer set for #{buffer}" if not f
        completer = f(buffer, context)
        append(completers, completer) if completer

  completers

at_most = (limit, t) ->
  return t if #t <= limit
  t2 = {}
  for i = 1,limit
    t2[#t2 + 1] = t[i]

  t2

differentiate_by_case = (prefix, completions) ->
  for i = 2, #completions
    first = completions[i - 1]
    second = completions[i]
    if first.ulower == second.ulower
      if second[1] == prefix[1]
        completions[i - 1] = second
        completions[i] = first

  completions

class Completer

  new: (buffer, pos) =>
    @buffer = buffer
    @context = buffer\context_at pos
    @start_pos = @context.word.start_pos
    @completers =
      [buffer.mode]: load_completers buffer, @context, buffer.mode

  complete: (pos, limit = @buffer.config.completion_max_shown) =>
    context = @context.start_pos == pos and @context or @buffer\context_at pos

    seen = {}
    completions = {}

    mode = @buffer\mode_at pos
    if not @completers[mode]
      @completers[mode] = load_completers @buffer, context, mode
    completers = @completers[mode]

    for completer in *completers
      comps = completer\complete context
      if comps
        if comps.authoritive
          completions = [c for c in *comps]
          break

        for comp in *comps
          unless seen[comp]
            append completions, comp
            seen[comp] = true

    prefix = context.word_prefix
    return differentiate_by_case(prefix, at_most(limit, completions)), prefix

  accept: (completion, pos) =>
    chunk = @buffer\context_at(pos).word
    chunk = @buffer\chunk(chunk.start_pos, pos - 1) unless @buffer.config.hungry_completion
    chunk.text = completion
    pos_after = chunk.start_pos + completion.ulen
    mode = @buffer\mode_at pos

    if mode.on_completion_accepted
      pos = mode\on_completion_accepted completion, @buffer\context_at(pos_after)
      pos_after = pos if type(pos) == 'number'

    pos_after

with config
  .define
    name: 'hungry_completion'
    description: 'Whether completing an item will cause the current word to be replaced'
    default: false
    type_of: 'boolean'

  .define
    name: 'completion_max_shown'
    description: 'Show at most this number of completions'
    default: 10
    type_of: 'number'

return Completer
