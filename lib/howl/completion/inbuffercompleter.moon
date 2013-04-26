import Matcher from howl.util

token_pattern = r'(\\pL[\\pL\\d_-]+)'
near_token_pattern = r'()(\\pL[\\pL\\d_-]+)'

parse = (buffer) ->
  tokens = { token, true for token in buffer.text\ugmatch token_pattern }
  [token for token, _ in pairs tokens]

near_tokens = (part, context) ->
  lines = context.buffer.lines
  line = context.line
  start_line = lines[math.max 1, line.nr - 10]
  end_line = lines[math.min #lines, line.nr + 10]
  tokens = {}
  close_chunk = context.buffer\chunk start_line.start_pos, end_line.end_pos
  line_pos = context.pos - start_line.start_pos

  for pos, token in close_chunk.text\ugmatch near_token_pattern
    rank = math.abs line_pos - pos
    info = tokens[token]
    rank = math.min info.rank, rank if info
    tokens[token] = :pos, :rank, text: token

  [token for _, token in pairs tokens]

class InBufferCompleter
  new: (buffer, context) =>
    @near_tokens = near_tokens context.word_prefix, context
    all_tokens = parse buffer
    @matcher = Matcher all_tokens

  complete: (context) =>
    pattern = '^' .. context.word_prefix .. '.'
    cur_word = context.word.text
    completions = {}

    for token in *@near_tokens
      append completions, token if token.text\match(pattern) and token.text != cur_word

    table.sort completions, (a, b) -> a.rank < b.rank
    completions = [c.text for c in *completions]

    if #completions < 10
      seen = { token, true for token in *completions }
      match_completions = self.matcher context.word_prefix
      i = 1
      while #completions < 10 and i <= #match_completions
        match_completion = match_completions[i]
        append completions, match_completion unless seen[match_completion] or match_completion == cur_word
        i += 1

    completions

howl.completion.register name: 'in_buffer', factory: InBufferCompleter
