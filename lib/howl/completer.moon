-- Copyright 2012-2024 The Howl Developers
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
          unless completer
            log.warn "unknown completer '#{f}' set for #{buffer} not found"
            continue

          f = completer.factory

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

completion_text = (compl) ->
  if type(compl) == 'table'
    return compl.completion or tostring compl[1]
  return compl

differentiate_by_case = (prefix, completions) ->
  for i = 2, #completions
    first = completions[i - 1]
    second = completions[i]
    first_text = completion_text first
    second_text = completion_text second
    if first_text.ulower == second_text.ulower
      if second_text[1] == prefix[1]
        completions[i - 1] = second
        completions[i] = first

  completions

class Completer

  new: (buffer, pos) =>
    @buffer = buffer
    @config = buffer\config_at pos
    @context = buffer\context_at pos
    @start_pos = @context.word.start_pos
    @completers =
      [buffer.mode]: load_completers buffer, @context, buffer.mode

  complete: (pos, limit = @config.completion_max_shown) =>
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

  accept: (compl, pos) =>
    compl = completion_text compl
    chunk = @buffer\context_at(pos).word
    chunk = @buffer\chunk(chunk.start_pos, pos - 1) unless @config.hungry_completion
    chunk.text = compl
    pos_after = chunk.start_pos + compl.ulen
    mode = @buffer\mode_at pos

    if mode.on_completion_accepted
      pos = mode\on_completion_accepted compl, @buffer\context_at(pos_after)
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
