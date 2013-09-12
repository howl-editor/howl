import config from howl

nrepl = bundle_load 'nrepl.moon'
parser = bundle_load 'clojure_parser.moon'

import Matcher from howl.util

get_ns = (buffer) ->
  clj = buffer.data.clojure
  unless clj
    clj = {}
    buffer.data.clojure = clj

  return clj.parsed.ns if clj.parsed

  clj.parsed = parser.parse buffer
  clj.parsed.ns

nrepl_complete = (buffer, prefix) ->
  if nrepl.is_connected
    ns = get_ns buffer
    ns_name = ns and ns.name or nil
    status, completions = pcall nrepl.complete, prefix, ns_name
    if status
      return [c for c in *completions when not c\match '%$']

  {}

class NReplCompleter
  new: (@buffer, context) =>
    @matcher = Matcher nrepl_complete buffer, ''

  complete: (context) =>
    prefix = context.word_prefix
    candidates = {}
    res = {}
    m = @matcher
    authoritive = false

    ref, divider = context.prefix\match '([%w-_./]+)([/.])[%w_-]*$'
    if ref
      clj_prefix = "#{ref}#{divider}"
      m = Matcher [c\sub(#clj_prefix + 1) for c in *nrepl_complete @buffer, clj_prefix]
      authoritive = true
    elseif #context.word_prefix < config.completion_popup_after
      return {}

    candidates = m prefix

    append res, c for c in *candidates when #res <= 10
    res.authoritive = authoritive if #candidates > 0
    res

howl.completion.register name: 'nrepl_completer', factory: NReplCompleter
