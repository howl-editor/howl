-- Copyright 2012-2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

Matcher = require 'howl.util.matcher'
import config, signal, app from howl
os = os
append = table.insert

RESCAN_STALE_AFTER = 60
MAX_TOKEN_LENGTH = 60

signal.connect 'buffer-modified', (args) ->
    data = args.buffer.data.inbuffer_completer
    data.is_stale = true if data

completion_buffers_for = (buffer) ->
  candidates = { buffer }
  max_buffers = buffer.config.inbuffer_completion_max_buffers
  same_only = buffer.config.inbuffer_completion_same_mode_only

  for b in *app.buffers
    if b != buffer and not same_only or b.mode == buffer.mode
      candidates[#candidates + 1] = b
    break if #candidates >= max_buffers

  candidates

should_update = (data) ->
  data.is_stale and os.difftime(os.time!, data.updated_at) > RESCAN_STALE_AFTER

load = (buffer) ->
  candidates = completion_buffers_for buffer

  tokens = {}
  for b in *candidates
    data = b.data.inbuffer_completer or {}
    b_tokens = data.tokens
    if not b_tokens or should_update data
      b_tokens = { token, true for token in b.text\ugmatch b.config.word_pattern when token.ulen <= MAX_TOKEN_LENGTH }
      data.tokens = b_tokens
      data.updated_at = os.time!
      b.data.inbuffer_completer = data

    tokens[token] = true for token in pairs b_tokens

  [token for token, _ in pairs tokens]

close_chunk = (context) ->
  lines = context.buffer.lines
  line = context.line
  start_line = lines[math.max 1, line.nr - 10]
  end_line = lines[math.min #lines, line.nr + 10]
  context.buffer\chunk start_line.start_pos, end_line.end_pos

near_tokens = (context) ->
  part = context.word_prefix
  cur_word = context.word.text
  chunk = close_chunk context
  line_pos = context.pos - chunk.start_pos

  tokens = {}
  start_pos = 1
  chunk_text = chunk.text
  buffer = context.buffer

  while start_pos < #chunk_text
    pattern = buffer\config_at(start_pos).word_pattern
    start_pos, end_pos = chunk_text\ufind pattern, start_pos
    break unless start_pos
    token = chunk_text\usub start_pos, end_pos
    if token != part and token != cur_word and token.ulen < MAX_TOKEN_LENGTH
      rank = math.abs line_pos - start_pos
      info = tokens[token]
      rank = math.min info.rank, rank if info
      tokens[token] = pos: start_pos, :rank, text: token
    start_pos = end_pos + 1

  data = buffer.data.inbuffer_completer
  if data and data.tokens
    data.tokens[token] = true for token in pairs tokens

  [token for _, token in pairs tokens]

class InBufferCompleter
  new: (buffer, context) =>
    @near_tokens = near_tokens context
    @matcher = Matcher load buffer
    @limit = buffer.config.completion_max_shown

  complete: (context) =>
    pattern = '^' .. context.word_prefix .. '.'
    cur_part = context.word_prefix
    cur_word = context.word.text
    candidates = {}

    current = (token) -> token == cur_word or token == cur_part

    for token in *@near_tokens
      append candidates, token if token.text\match(pattern) and not current(token.text)

    table.sort candidates, (a, b) -> a.rank < b.rank
    completions = {}
    append completions, c.text for c in *candidates when #completions < @limit

    if #completions < @limit
      seen = { token, true for token in *completions }
      match_completions = self.matcher context.word_prefix
      i = 1
      while #completions < @limit and i <= #match_completions
        match_completion = match_completions[i]
        append completions, match_completion unless seen[match_completion] or current(match_completion)
        i += 1

    completions

with config
  .define
    name: 'inbuffer_completion_max_buffers'
    description: 'The maxium number of buffers that the inbuffer completer should search'
    default: 6
    type_of: 'number'

with config
  .define
    name: 'inbuffer_completion_same_mode_only'
    description: 'Whether the inbuffer completer only completes from buffers with the same mode'
    default: false
    type_of: 'boolean'

howl.completion.register name: 'in_buffer', factory: InBufferCompleter
