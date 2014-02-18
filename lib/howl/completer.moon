-- Copyright 2012-2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE.md)

import completion, config from howl

load_completers = (buffer, context) ->
  completers = {}

  mode = buffer.mode or {}
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

class Completer

  new: (buffer, pos) =>
    @buffer = buffer
    @context = buffer\context_at pos
    @start_pos = @context.word.start_pos
    @completers = load_completers buffer, @context

  complete: (pos, limit = @buffer.config.completion_max_shown) =>
    context = @context.start_pos == pos and @context or @buffer\context_at pos

    seen = {}
    completions = {}

    for completer in *@completers
      comps = completer\complete context
      if comps
        if comps.authoritive
          completions = [c for c in *comps]
          break

        for comp in *comps
          unless seen[comp]
            append completions, comp
            seen[comp] = true

    return at_most(limit, completions), context.word_prefix

  accept: (completion, pos) =>
    chunk = @buffer\context_at(pos).word
    chunk = @buffer\chunk(chunk.start_pos, pos - 1) unless @buffer.config.hungry_completion
    chunk.text = completion
    pos_after = chunk.start_pos + completion.ulen

    if @buffer.mode.on_completion_accepted
      pos = @buffer.mode\on_completion_accepted completion, @buffer\context_at(pos_after)
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
