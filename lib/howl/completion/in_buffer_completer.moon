-- Copyright 2012-2018 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

Matcher = require 'howl.util.matcher'
GRegex = require 'ljglibs.glib.regex'
{:config, :signal, :app} = howl
{:abs, :min, :max} = math
os = os
append = table.insert

RESCAN_STALE_AFTER = 60
MAX_TOKEN_SIZE = 100

signal.connect 'buffer-modified', (args) ->
    data = args.buffer.data.inbuffer_completer
    data.is_stale = true if data

completion_buffers_for = (buffer, conf) ->
  candidates = { buffer }
  max_buffers = conf.inbuffer_completion_max_buffers
  same_only = conf.inbuffer_completion_same_mode_only

  for b in *app.buffers
    if b != buffer and not same_only or b.mode == buffer.mode
      candidates[#candidates + 1] = b
    break if #candidates >= max_buffers

  candidates

should_update = (data) ->
  data.is_stale and os.difftime(os.time!, data.updated_at) > RESCAN_STALE_AFTER

load = (buffer, conf) ->
  candidates = completion_buffers_for buffer, conf

  tokens = {}
  for b in *candidates
    data = b.data.inbuffer_completer or {}
    b_tokens = data.tokens
    if not b_tokens or should_update data
      b_tokens = {}
      p = GRegex b.mode.word_pattern.pattern
      ptr = b\get_ptr 1, b.length
      match_info = p\match_with_info ptr
      if match_info
        while match_info\matches!
          token = match_info\fetch(0)
          b_tokens[token] = true if #token <= MAX_TOKEN_SIZE
          match_info\next!

      data.tokens = b_tokens
      data.updated_at = os.time!
      b.data.inbuffer_completer = data

    tokens[token] = true for token in pairs b_tokens

  [token for token, _ in pairs tokens]

close_chunk = (context) ->
  SIZE = 3000
  buffer = context.buffer
  pos = context.pos
  start_pos = max 1, pos - (SIZE / 2)
  end_pos = min buffer.length, pos + (SIZE / 2)

  if end_pos - start_pos < SIZE
    start_pos = max 1, start_pos - (SIZE / 2)
    end_pos = min buffer.length, pos + (SIZE / 2)

  buffer\chunk start_pos, end_pos

near_tokens = (context, conf) ->
  part = context.word_prefix
  cur_word = context.word.text
  chunk = close_chunk context

  tokens = {}
  start_pos = 1
  chunk_text = chunk.text
  buffer = context.buffer

  -- determine the current context's byte position within the close chunk
  cur_byte_pos = buffer\byte_offset context.pos
  close_byte_pos = buffer\byte_offset chunk.start_pos
  cur_pos = cur_byte_pos - close_byte_pos
  pattern = buffer.mode.word_pattern
  match_info = pattern.re\match_with_info chunk_text
  if match_info
    while match_info\matches!
      token = match_info\fetch(0)
      if token != part and token != cur_word and #token <= MAX_TOKEN_SIZE
        start_pos = match_info\fetch_pos(0)
        rank = abs cur_pos - start_pos
        info = tokens[token]
        rank = min info.rank, rank if info
        tokens[token] = :rank, text: token

      match_info\next!

  data = buffer.data.inbuffer_completer
  if data and data.tokens
    data.tokens[token] = true for token in pairs tokens

  [token for _, token in pairs tokens]

class InBufferCompleter
  new: (buffer, context) =>
    config = buffer\config_at context.pos
    @near_tokens = near_tokens context, config
    @matcher = Matcher load buffer, config
    @limit = config.completion_max_shown

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
