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

        error '`nil` completer set for ' .. buffer if not f
        completer = f(buffer, context)
        append(completers, completer) if completer

  completers

class Completer

  new: (buffer, pos) =>
    @buffer = buffer
    @context = buffer\context_at pos
    @start_pos = @context.word.start_pos
    @completers = load_completers buffer, @context

  complete: (pos) =>
    context = @context.start_pos == pos and @context or @buffer\context_at pos

    completions = {}

    for completer in *@completers
      comps = completer\complete context
      if comps
        append completions, comp for comp in *comps

    return completions, context.word_prefix

  accept: (completion, pos) =>
    chunk = @buffer\context_at(pos).word
    chunk = @buffer\chunk(chunk.start_pos, pos - chunk.start_pos) unless @buffer.config.hungry_completion
    chunk.text = completion
    chunk.start_pos + #completion

config.define
  name: 'hungry_completion'
  description: 'Whether completing an item will cause the entire current word to be replaced'
  default: false
  type_of: 'boolean'

return Completer
