-- Copyright 2012-2016 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

{insert: append, :concat} = table
max = math.max
{:type, :tostring} = _G

separator = ' \t-_:/'
sep_p = "[#{separator}]+"
non_sep_p = "[^#{separator}]"
leading_greedy_p = "(?:^|.*#{sep_p})"
leading_p = "(?:^|.*?#{sep_p})"

boundary_part_p = (p) ->
  "(?:#{p}|#{non_sep_p}*#{sep_p}#{p})()"

case_boundary_part_p = (p) ->
  upper = p.uupper
  "(?:#{p}|#{upper}|.+#{upper})()"

boundary_pattern = (search, reverse) ->
  parts = [r.escape(search[i]) for i = 1, search.ulen]
  leading = reverse and leading_greedy_p or leading_p
  p = leading .. parts[1] .. '()'
  p ..= concat [boundary_part_p(parts[i]) for i = 2, #parts]
  r(p)

case_boundary_pattern = (search, reverse) ->
  parts = [r.escape(search[i]) for i = 1, search.ulen]
  leading = reverse and leading_greedy_p or leading_p
  p = leading
  p ..= concat [case_boundary_part_p(part) for part in *parts]
  r(p)

score_for = (match, text, match_type, reverse, base_score) ->
  len = text.ulen

  if match_type == 'exact'
    if reverse
      return base_score + (len - match[2])
    else
      return len + (match[1] + base_score)

  -- boundary
  length_penalty = (len - base_score) / 3
  if reverse
    (len - match[1]) + length_penalty
  else
    start_pos = match[1]
    end_pos = match[#match]
    (end_pos - start_pos) + start_pos + length_penalty

create_matcher = (search, reverse) ->
  search = search.ulower
  boundary_p = boundary_pattern search, reverse
  case_boundary_p = case_boundary_pattern search, reverse

  {:find, :sub} = string

  possible_match = (item) ->
    pos = 1
    for i = 1, #search
      p = find item, sub(search, i, i), pos, true
      return false unless p
      pos = p + 1

    true

  (text, case_text) ->
    return nil unless possible_match(text)
    match = { boundary_p\match text }
    return 'boundary', match if #match > 0
    match = { case_boundary_p\match case_text }
    return 'boundary', match if #match > 0
    match = { text\ufind search, 1, true }
    return 'exact', match if #match > 0
    nil

load_entries = (candidates) ->
  max_len = 0

  entries = if type(candidates[1]) == 'table' and #candidates[1] > 0
    for candidate in *candidates
      text = concat [tostring(c) for c in *candidate], ' '
      max_len = max max_len, #text
      text: text.ulower, case_text: text, :candidate
  else
    for candidate in *candidates
      text = tostring candidate
      max_len = max max_len, #text
      text: text.ulower, case_text: text, :candidate

  entries.base_score = max_len * 3
  entries

class Matcher

  new: (@candidates, @options = {}) =>
    @cache = entries: {}, matches: {}
    @entries = load_entries candidates

  __call: (search) =>
    return @candidates if not search or search.is_empty

    search = search.ulower
    matches = @cache.matches[search]
    if matches then return matches.items, matches.partial
    matches = {}

    prev_search_part = search\usub 1, -2
    entries = @cache.entries[prev_search_part] or @entries
    matching_entries = {}
    matcher = create_matcher search, @options.reverse
    partial = false

    partial_limit = #@entries > 1100 and 1000 or 1100

    for entry in *entries
      text = entry.text
      continue if #text < #search
      match_type, match = matcher text, entry.case_text

      if match
        if #matches >= partial_limit
          partial = true
          break

        score = score_for match, text, match_type, @options.reverse, @entries.base_score
        append matches, entry: entry, :score
        append matching_entries, entry

    unless @options.preserve_order
      table.sort matches, (a ,b) -> a.score < b.score

    matching_candidates = [match.entry.candidate for match in *matches]

    @cache.matches[search] = {items: matching_candidates, :partial}

    unless partial
      @cache.entries[search] = matching_entries

    matching_candidates, partial

  explain: (search, text, options = {}) ->
    how, match = create_matcher(search, options.reverse)(text.ulower, text)
    return nil unless match

    segments = {}
    if how == 'exact'
      { start_pos, end_pos } = match
      append segments, {start_pos, end_pos - start_pos + 1}
    else -- boundary
      match[i] -= 1 for i = 1, #match
      local segment_start, segment_end
      for pos in *match
        unless segment_start
          segment_start = pos
          segment_end = pos
          continue
        if pos == segment_end + 1
          segment_end = pos
        else
          table.insert segments, {segment_start, segment_end - segment_start + 1}
          segment_start = pos
          segment_end = pos
      if segment_start
        table.insert segments, {segment_start, segment_end - segment_start + 1}

    segments.how = how
    return segments

return Matcher
