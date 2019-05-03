-- Copyright 2012-2017 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

ffi = require 'ffi'
GRegex = require 'ljglibs.glib.regex'
{insert: append, :concat} = table
max = math.max
{:type, :tostring, :tonumber} = _G
{:escape_string} = GRegex
{:C} = ffi

separator = ' \t-_:/'
sep_p = "[#{separator}]+"
non_sep_p = "[^#{separator}]"
leading_greedy_p = "(?:^|.*#{sep_p})"
leading_p = "(?:^|.*?#{sep_p})"

boundary_part_p = (p) ->
  "(?:(#{p})|#{non_sep_p}*#{sep_p}(#{p}))"

case_boundary_part_p = (p) ->
  upper = p.uupper
  "(?:(#{p})|.*?(#{upper}))"

boundary_pattern = (search, reverse) ->
  parts = [escape_string(search[i]) for i = 1, search.ulen]
  leading = reverse and leading_greedy_p or leading_p
  p = leading .. '(' .. parts[1] .. ')'
  p ..= concat [boundary_part_p(parts[i]) for i = 2, #parts]
  GRegex(p)

case_boundary_pattern = (search, reverse) ->
  parts = [escape_string(search[i]) for i = 1, search.ulen]
  leading = reverse and leading_greedy_p or leading_p
  p = leading
  p ..= concat [case_boundary_part_p(part) for part in *parts]
  GRegex(p)

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
  mi = ffi.new('GMatchInfo *[1]')
  start_pos = ffi.new 'gint[1]'
  end_pos = ffi.new 'gint[1]'
  empty = {}

  {:find, :sub} = string

  possible_match = (item) ->
    pos = 1
    for i = 1, #search
      p = find item, sub(search, i, i), pos, true
      return false unless p
      pos = p + 1

    true

  do_match = (p, text) ->
    matched = C.g_regex_match(p, text, 0, mi) != 0
    return empty unless matched
    info = mi[0]
    count = C.g_match_info_get_match_count(info)
    return empty unless count > 0
    match = {}

    for i = 1, count - 1
      C.g_match_info_fetch_pos(info, i, start_pos, end_pos)
      s_pos = start_pos[0]
      if s_pos != -1
        append match, tonumber(s_pos) + 1

    C.g_match_info_unref info
    match

  last_char = search\usub(search.ulen, search.ulen).ulower

  trim = (text, case_text) ->
    -- trim end of text and case_text to segment that might possibly match
    last_pos = text\rfind last_char
    if last_pos
      last_pos += last_char.ulen
      case_text = case_text\sub(1, last_pos) if case_text
      return text\sub(1, last_pos), case_text

  (text, case_text) ->
    -- triming the end speeds up regex matching
    text, case_text = trim text, case_text
    return nil unless text

    return nil unless possible_match(text)

    match = do_match boundary_p, text
    return 'boundary', match if #match > 0

    if case_text
      match = do_match case_boundary_p, case_text
      return 'boundary', match if #match > 0

    match = { text\find search, 1, true }
    return 'exact', match if #match > 0
    nil

load_entries = (candidates) ->
  max_len = 0
  t_candidates = type(candidates[1]) == 'table' and #candidates[1] > 0

  entries = if t_candidates
    for candidate in *candidates
      text = concat [tostring(c) for c in *candidate], ' '
      max_len = max max_len, #text
      lower = text.ulower
      case_text = text if text != lower
      text: lower, :case_text, :candidate
  else
    for candidate in *candidates
      text = tostring candidate
      max_len = max max_len, #text
      lower = text.ulower
      case_text = text if text != lower
      text: lower, :case_text, :candidate

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
    if matches then return matches.items, partial: matches.partial, positions: matches.positions
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
        append matches, entry: entry, :score, how: match_type, positions: text\char_offset match
        append matching_entries, entry

    unless @options.preserve_order
      table.sort matches, (a ,b) -> a.score < b.score

    matching_candidates = [match.entry.candidate for match in *matches]

    -- each position is a table {start_pos, end_pos} or {pos1, pos2, pos3, ...}
    -- indicating what part of the candidate matched
    positions = [match.positions for match in *matches]

    @cache.matches[search] = {items: matching_candidates, :partial, :positions}

    unless partial
      @cache.entries[search] = matching_entries

    matching_candidates, :partial, :positions

  explain: (search, text, options = {}) ->
    how, match = create_matcher(search, options.reverse)(text.ulower, text)
    return nil unless match

    match = text\char_offset match
    segments = {}
    if how == 'exact'
      { start_pos, end_pos } = match
      append segments, {start_pos, end_pos - start_pos + 1}
    else -- boundary
      local segment_start, segment_end
      for pos in *match
        unless segment_start
          segment_start = pos
          segment_end = pos
          continue
        if pos == segment_end + 1
          segment_end = pos
        else
          append segments, {segment_start, segment_end - segment_start + 1}
          segment_start = pos
          segment_end = pos
      if segment_start
        append segments, {segment_start, segment_end - segment_start + 1}

    segments.how = how
    return segments

  :create_matcher

return Matcher
