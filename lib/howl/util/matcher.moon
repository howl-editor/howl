-- Copyright 2012-2013 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

lpeg = require 'lpeg'
import B, P, V, S, Cp, Ct, Cc, Cg from lpeg

separator = S ' \t-_:/\\'

forward_boundary_pattern = (search) ->
  pattern = P true

  for i = 1, search.ulen do
    c = P search[i]
    boundary_p = separator * Cp! * c
    pattern *= (Cp! * c) + (-boundary_p * -separator * P 1)^0 * boundary_p

  pattern

reverse_boundary_pattern = (search) ->
  pattern = P true
  boundary_del = P(-1) + separator

  prev_p = false
  for i = 1, search.ulen do
    c = P search[i]
    next = search[i + 1]
    next_p = next.empty and boundary_del or (#P(next) + boundary_del)
    match_p = (Cp! * c * next_p)
    pattern *= match_p + (-B(prev_p) * (-match_p * -next_p * P(1))^0) * match_p
    prev_p = c

  pattern

match_pattern = (search, reverse) ->
  search = search.ureverse if reverse
  fuzzy = Cg Cc('fuzzy'), 'how'
  boundary = Cg Cc('boundary'), 'how'
  exact = Cg(Cc('exact'), 'how') * Cp! * P search

  boundary *= reverse and reverse_boundary_pattern(search) or forward_boundary_pattern(search)

  for i = 1, search.ulen do
    c = P search[i]
    fuzzy *= (-c * P 1)^0 * Cp! * c

  Ct P {
    boundary + V('exact') + fuzzy
    exact: exact + P(1) * V 'exact'
  }

do_match = (text, pattern, base_score) ->
  match = pattern\match text
  return nil unless match
  start_pos = match[1]
  end_pos = match[#match]
  len = text.ulen
  switch match.how
    when 'exact'
      len + (start_pos + base_score)
    when 'fuzzy'
      len + (end_pos - start_pos) + base_score * 2
    when 'boundary'
      len + (end_pos - start_pos) + start_pos

class Matcher
  new: (@candidates, @options = {}) =>
    @_load_candidates!

  __call: (search) =>
    return @candidates if not search or #search == 0

    search = search.ulower
    prev_search = search\usub 1, -2
    matches = @cache.matches[search] or {}
    if #matches > 0 then return matches

    lines = @cache.lines[search\usub 1, -2] or @lines
    matching_lines = {}
    pattern = match_pattern search, @options.reverse

    for i, line in ipairs lines
      score = do_match line.text, pattern, @base_score
      if score then
        append matches, index: line.index, :score
        append matching_lines, line

    @cache.lines[search] = matching_lines

    table.sort matches, (a ,b) -> a.score < b.score
    matching_candidates = [@candidates[match.index] for match in *matches]
    @cache.matches[search] = matching_candidates
    matching_candidates

  explain: (search, text, options = {}) ->
    pattern = match_pattern search.ulower, options.reverse
    text = text.ureverse if options.reverse
    match = pattern\match text.ulower
    return nil unless match
    how = match.how
    if how == 'exact'
      for pos = match[1] + 1, match[1] + search.ulen - 1
        append match, pos


    char_match = text\char_offset match

    if options.reverse
      char_match = [text.ulen - p + 1 for p in * char_match]
      table.sort char_match

    char_match.how = how
    return char_match

  _load_candidates: =>
    max = math.max

    @cache = lines: {}, matches: {}
    @lines = {}
    max_len = 0

    for i, candidate in ipairs @candidates do
      text = if type(candidate) == 'table' and #candidate > 0
        table.concat [tostring(c) for c in *candidate], ' '
      else
        text = tostring candidate

      text = text.ulower
      text = text.ureverse if @options.reverse
      append @lines, index: i, :text
      max_len = max max_len, #text

    @base_score = max_len * 3

return Matcher
