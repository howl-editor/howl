match_score = (line, matchers) ->
  score = 0

  for matcher in *matchers
    matcher_score = matcher line
    if not matcher_score then return nil
    score = score + matcher_score

  score

pattern_escapes = { c, '%' .. c for c in string.gmatch('^$()%.[]*+-?', '.') }

fuzzy_search_pattern = (search) ->
  pattern = ''
  for i = 1, #search do
    c = search\sub(i, i)
    c = pattern_escapes[c] or c
    pattern = pattern .. c .. '.-'

  pattern

class Matcher
  new: (candidates, anywhere, case_insensitive, fuzzy) =>
    @candidates = candidates
    @anywhere = anywhere
    @case_insensitive = case_insensitive
    @fuzzy = fuzzy
    @_load_candidates!

  __call: (search) =>
    return @candidates if not search or #search == 0

    search = search\lower! if @case_insensitive
    matches = @cache.matches[search] or {}
    if #matches > 0 then return matches

    lines = @cache.lines[string.sub(search, 1, -2)] or @lines
    matchers = @_matchers_for_search search

    matching_lines = {}
    for i, line in ipairs lines
      score = match_score line.text, matchers
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
    @fuzzy_score_penalty = 0

    for i, candidate in ipairs @candidates do
      text = candidate
      if type(candidate) == 'table' then text = table.concat candidate, ' '
      if @case_insensitive then text = text\lower!
      append @lines, index: i, :text
      @fuzzy_score_penalty = max @fuzzy_score_penalty, #text

  _matchers_for_search: (search_string) =>
    fuzzy = @fuzzy
    fuzzy_penalty = @fuzzy_score_penalty

    groups = [part for part in search_string\gmatch('%S+')]
    matchers = {}

    for search in *groups
      fuzzy_pattern = fuzzy and fuzzy_search_pattern search
      append matchers, (line) ->
        start_pos, end_pos = line\find search, 1, true
        score = start_pos
        if not start_pos and fuzzy
          start_pos, end_pos = line\find fuzzy_pattern
          if start_pos then score = (end_pos - start_pos) + fuzzy_penalty

        if score and (@anywhere or start_pos == 1)
          return score + #line, start_pos, end_pos, search

    return matchers

return Matcher
