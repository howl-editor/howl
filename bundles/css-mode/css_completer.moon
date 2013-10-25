-- Copyright 2013 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE.md)

import Matcher from howl.util

local properties, properties_matcher

authoritive = (t) ->
  with t
    .authoritive = true

css_context = (context) ->
  property = context.prefix\match '([%w-]+)%s*:%s[^;:]*$'
  return 'property', property if property
  return 'selector' if context.prefix\match '{[^}]*$'

  line = context.line.previous
  while line
    return 'selector' if line\match '{%s*$'
    return if line\match '}%s*$'
    line = line.previous

complete = (context) =>
  ctx, value = css_context context
  if ctx == 'selector'
    return authoritive(properties_matcher context.word_prefix)

  if ctx == 'property'
    def = properties[value]
    candidates = def and [k for k in pairs def.values]
    return authoritive(Matcher(candidates) context.word_prefix) if candidates

->
  properties = bundle_load 'css_properties.moon'
  properties_matcher = Matcher [p for p in pairs properties]
  :complete
