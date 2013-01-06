import completion from howl

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

    return completions

return Completer
