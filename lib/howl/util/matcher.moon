lpeg = require 'lpeg'
import P, V, S, Cp, Ct, Cc, Cg from lpeg

separator = S ' \t-_:/\\'

match_pattern = (search) ->
  fuzzy = Cg Cc('fuzzy'), 'how'
  boundary = Cg Cc('boundary'), 'how'
  exact = Cg(Cc('exact'), 'how') * Cp! * P search

  for i = 1, search.ulen do
    c = P search[i]
    fuzzy *= (-c * P 1)^0 * Cp! * c
    boundary_p = separator * Cp! * c
    boundary *= Cp! * c + (-boundary_p * -separator * P 1)^0 * boundary_p

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
      len + (end_pos - start_pos)

class Matcher
  new: (candidates) =>
    @candidates = candidates
    @_load_candidates!

  __call: (search) =>
    return @candidates if not search or #search == 0

    search = search.ulower
    prev_search = search\usub 1, -2
    matches = @cache.matches[search] or {}
    if #matches > 0 then return matches

    lines = @cache.lines[search\usub 1, -2] or @lines
    matching_lines = {}
    pattern = match_pattern search

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

  explain: (search, text) ->
    pattern = match_pattern search.ulower
    match = pattern\match text.ulower
    return nil unless match
    if match.how == 'exact'
      for pos = match[1] + 1, match[1] + search.ulen - 1
        append match, pos

    char_match = text\char_offset match
    char_match.how = match.how
    return char_match

  _load_candidates: =>
    max = math.max

    @cache = lines: {}, matches: {}
    @lines = {}
    max_len = 0

    for i, candidate in ipairs @candidates do
      text = candidate
      if type(candidate) == 'table' then text = table.concat candidate, ' '
      text = text.ulower
      append @lines, index: i, :text
      max_len = max max_len, #text

    @base_score = max_len * 3

return Matcher
