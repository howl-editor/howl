-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE.md)

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
  mode = buffer.mode
  if mode.api
    {
      :complete
      :mode
      api: mode.api
    }
