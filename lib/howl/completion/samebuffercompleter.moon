parse = (buffer, line) ->
  line_pos = line.start_pos
  tokens = {}

  for pos, token in buffer.text\gmatch '()([%a_][%w_-]+)'
    token = tostring token
    rank = math.abs line_pos - pos
    info = tokens[token]
    rank = math.min info.rank, rank if info
    tokens[token] = :pos, :rank, text: token

  [token for _, token in pairs tokens]

class SameBufferCompleter
  new: (buffer, context) =>
    @tokens = parse buffer, context.line

  complete: (word, pos) =>
    pattern = '^' .. word .. '.'
    completions = {}
    for token in *@tokens
      append completions, token if token.text\match tostring pattern

    table.sort completions, (a, b) -> a.rank < b.rank
    [c.text for c in *completions]

howl.completion.register name: 'same_buffer', factory: SameBufferCompleter
