-- Copyright 2013 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE.md)

import Matcher from howl.util
import colors from howl.ui

local properties, properties_matcher, color_matcher

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

complete_color = (context) ->
  return authoritive(color_matcher context.word_prefix)

complete = (context) =>
  ctx, value = css_context context
  if ctx == 'selector'
    return authoritive(properties_matcher context.word_prefix)

  if ctx == 'property'
    return complete_color(context) if value\ends_with 'color'
    def = properties[value]
    candidates = def and [k for k in pairs def.values]
    return authoritive(Matcher(candidates) context.word_prefix) if candidates

finish_completion = (completion, context) ->
  if css_context(context) == 'selector'
    context.buffer\insert ': ', context.pos
    return context.pos + 2

->
  properties = bundle_load 'css_properties'
  properties_matcher = Matcher [p for p in pairs properties]
  color_matcher = Matcher [n for n in pairs colors when n != 'reverse']
  {
    :complete
    :finish_completion
  }
