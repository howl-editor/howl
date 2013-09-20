-- Copyright 2012-2013 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

import Matcher from howl.util

parse = (buffer) ->
  tokens = { token, true for token in buffer.text\ugmatch buffer.config.word_pattern }
  [token for token, _ in pairs tokens]

close_chunk = (context) ->
  lines = context.buffer.lines
  line = context.line
  start_line = lines[math.max 1, line.nr - 10]
  end_line = lines[math.min #lines, line.nr + 10]
  context.buffer\chunk start_line.start_pos, end_line.end_pos

near_tokens = (part, context) ->
  chunk = close_chunk context
  line_pos = context.pos - chunk.start_pos

  tokens = {}
  start_pos = 1
  chunk_text = chunk.text
  pattern = context.buffer.config.word_pattern

  while start_pos < #chunk_text
    start_pos, end_pos = chunk_text\ufind pattern, start_pos
    break unless start_pos
    token = chunk_text\usub start_pos, end_pos
    rank = math.abs line_pos - start_pos
    info = tokens[token]
    rank = math.min info.rank, rank if info
    tokens[token] = pos: start_pos, :rank, text: token
    start_pos = end_pos + 1

  [token for _, token in pairs tokens]

class InBufferCompleter
  new: (buffer, context) =>
    @near_tokens = near_tokens context.word_prefix, context
    @matcher = Matcher parse buffer

  complete: (context) =>
    pattern = '^' .. context.word_prefix .. '.'
    cur_word = context.word.text
    candidates = {}

    for token in *@near_tokens
      append candidates, token if token.text\match(pattern) and token.text != cur_word

    table.sort candidates, (a, b) -> a.rank < b.rank
    completions = {}
    append completions, c.text for c in *candidates when #completions < 10

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
