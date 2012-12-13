lpeg = require 'lpeg'
import P, V, S, Cp, Ct, Cc from lpeg

separator = S ' \t-_:/\\'

match_pattern = (search) ->
  fuzzy = Cc 'fuzzy'
  boundary = Cc 'boundary'
  exact = Cc('exact') * Cp! * P(search) * Cp!

  for i = 1, #search do
    c = P search\sub(i, i)
    fuzzy *= (-c * P 1)^0 * Cp! * c
    boundary_p = separator * c
    boundary *= Cp! * c + (-boundary_p * P 1)^0 * Cp! * boundary_p

  fuzzy *= Cp!
  boundary *= Cp!

  Ct P {
    boundary + V('exact') + fuzzy
    exact: exact + P(1) * V 'exact'
  }

do_match = (text, pattern, base_score) ->
  match = pattern\match text
  return nil unless match and #match > 0
  start_pos = match[2]
  end_pos = match[#match]
  switch match[1]
    when 'exact'
      end_pos + base_score
    when 'fuzzy'
      (end_pos - start_pos) + base_score * 2
    when 'boundary'
      end_pos - start_pos

class Matcher
  new: (candidates) =>
    @candidates = candidates
    @_load_candidates!

  __call: (search) =>
    return @candidates if not search or #search == 0

    search = search\lower!
    matches = @cache.matches[search] or {}
    if #matches > 0 then return matches

    lines = @cache.lines[string.sub(search, 1, -2)] or @lines
    matching_lines = {}
    pattern = match_pattern search, @base_score

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

  _load_candidates: =>
    max = math.max

    @cache = lines: {}, matches: {}
    @lines = {}
    @base_score = 0

    for i, candidate in ipairs @candidates do
      text = candidate
      if type(candidate) == 'table' then text = table.concat candidate, ' '
      text = text\lower!
      append @lines, index: i, :text
      @base_score = max @base_score, #text

return Matcher
