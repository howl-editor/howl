class Completer

  new: (buffer, pos) =>
    @buffer = buffer
    @line = @buffer.lines\at_pos pos
    @start_pos = @buffer\word_at(pos).start_pos
    @prefix = @line\sub 1, @start_pos - @line.start_pos

  complete: (pos) =>
    mode = @buffer.mode or {}
    completers = {}

    for source in *{@buffer.completers, mode.completers}
      if source
        append completers, c for c in *source

    return @_fetch_completions completers, pos

  _fetch_completions: (completers, pos) =>
    word = @buffer\chunk @start_pos, pos - @start_pos
    up_to_pos = word.text\sub 1, pos - @start_pos

    completions = {}

    for completer in *completers
      comps = completer up_to_pos, @prefix, @buffer, @line
      if comps
        append completions, comp for comp in *comps

    return completions

return Completer
