-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import Matcher from howl.util
matchers = {}

matcher_for = (path = '', parts = {}, api) ->
  m = matchers[path]
  return m if m

  node = api
  for part in *parts
    node = node[part]
    return nil unless node

  m = Matcher [c for c in pairs node]
  matchers[path] = m
  m

complete = (context) =>
  path, parts = @mode\resolve_type context
  matcher = matcher_for(path, parts, @api)
  candidates = matcher and matcher(context.word_prefix) or {}
  if #candidates > 0 and #parts > 0
    candidates.authoritive = true
  candidates

howl.completion.register name: 'api', factory: (buffer, context) ->
  mode = buffer\mode_at context.pos
  if mode.api
    {
      :complete
      :mode
      api: mode.api
    }
