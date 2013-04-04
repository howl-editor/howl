ffi = require 'ffi'

import GError, gint, const_char_p from howl.cdefs
import C from ffi

ffi.cdef [[
  typedef enum {
    G_REGEX_CASELESS          = 1 << 0,
    G_REGEX_MULTILINE         = 1 << 1,
    G_REGEX_DOTALL            = 1 << 2,
    G_REGEX_EXTENDED          = 1 << 3,
    G_REGEX_ANCHORED          = 1 << 4,
    G_REGEX_DOLLAR_ENDONLY    = 1 << 5,
    G_REGEX_UNGREEDY          = 1 << 9,
    G_REGEX_RAW               = 1 << 11,
    G_REGEX_NO_AUTO_CAPTURE   = 1 << 12,
    G_REGEX_OPTIMIZE          = 1 << 13,
    G_REGEX_FIRSTLINE         = 1 << 18,
    G_REGEX_DUPNAMES          = 1 << 19,
    G_REGEX_NEWLINE_CR        = 1 << 20,
    G_REGEX_NEWLINE_LF        = 1 << 21,
    G_REGEX_NEWLINE_CRLF      = G_REGEX_NEWLINE_CR | G_REGEX_NEWLINE_LF,
    G_REGEX_NEWLINE_ANYCRLF   = G_REGEX_NEWLINE_CR | 1 << 22,
    G_REGEX_BSR_ANYCRLF       = 1 << 23,
    G_REGEX_JAVASCRIPT_COMPAT = 1 << 25
  } GRegexCompileFlags;

  typedef enum {
    G_REGEX_MATCH_ANCHORED         = 1 << 4,
    G_REGEX_MATCH_NOTBOL           = 1 << 7,
    G_REGEX_MATCH_NOTEOL           = 1 << 8,
    G_REGEX_MATCH_NOTEMPTY         = 1 << 10,
    G_REGEX_MATCH_PARTIAL          = 1 << 15,
    G_REGEX_MATCH_NEWLINE_CR       = 1 << 20,
    G_REGEX_MATCH_NEWLINE_LF       = 1 << 21,
    G_REGEX_MATCH_NEWLINE_CRLF     = G_REGEX_MATCH_NEWLINE_CR | G_REGEX_MATCH_NEWLINE_LF,
    G_REGEX_MATCH_NEWLINE_ANY      = 1 << 22,
    G_REGEX_MATCH_NEWLINE_ANYCRLF  = G_REGEX_MATCH_NEWLINE_CR | G_REGEX_MATCH_NEWLINE_ANY,
    G_REGEX_MATCH_BSR_ANYCRLF      = 1 << 23,
    G_REGEX_MATCH_BSR_ANY          = 1 << 24,
    G_REGEX_MATCH_PARTIAL_SOFT     = G_REGEX_MATCH_PARTIAL,
    G_REGEX_MATCH_PARTIAL_HARD     = 1 << 27,
    G_REGEX_MATCH_NOTEMPTY_ATSTART = 1 << 28
  } GRegexMatchFlags;

  typedef struct {} GRegex;
  typedef struct {} GMatchInfo;

  GRegex *      g_regex_new               (const gchar *pattern,
                                           GRegexCompileFlags compile_options,
                                           GRegexMatchFlags match_options,
                                           GError **error);
  void          g_regex_unref             (GRegex *regex);
  const gchar * g_regex_get_pattern       (const GRegex *regex);
  gint          g_regex_get_capture_count (const GRegex *regex);
  gboolean      g_regex_match             (const GRegex *regex,
                                           const gchar *string,
                                           GRegexMatchFlags match_options,
                                           GMatchInfo **match_info);
  gchar *       g_regex_escape_string     (const gchar *string, gint length);

  gint      g_match_info_get_match_count(const GMatchInfo *match_info);
  gboolean  g_match_info_matches        (const GMatchInfo *match_info);
  gboolean  g_match_info_next           (GMatchInfo *match_info, GError **error);
  gchar *   g_match_info_fetch          (const GMatchInfo *match_info, gint match_num);
  void      g_match_info_unref          (GMatchInfo *match_info);
  gboolean  g_match_info_fetch_pos      (const GMatchInfo *match_info,
                                         gint match_num,
                                         gint *start_pos,
                                         gint *end_pos);
]]

free_match_info = (mi) -> C.g_match_info_unref mi[0]

do_match = (p, s, init) ->
  s = s\usub init unless init == 1
  return nil unless #s > 0
  ptr = const_char_p s
  mi = ffi.new 'GMatchInfo *[1]'
  matched = C.g_regex_match p, ptr, 0, mi
  if matched == 0
    free_match_info mi
    return nil

  count = C.g_match_info_get_match_count mi[0]
  mi, ptr, count

get_capture_string = (mi, index) ->
  cs_match = C.g_match_info_fetch(mi[0], index)
  error "Failed to fetch capture #{index}" if cs_match == nil
  match = ffi.string cs_match
  C.g_free cs_match
  match

get_capture = (match_info, index, ptr, fetch_positions = false) ->
  match = get_capture_string match_info, index
  return match unless fetch_positions or #match == 0

  start_pos = ffi.new 'gint[1]'
  end_pos = ffi.new 'gint[1]'

  if C.g_match_info_fetch_pos(match_info[0], index, start_pos, end_pos) == 0
    return match

  start_ptr = ptr + start_pos[0]
  start_offset = tonumber 1 + C.g_utf8_pointer_to_offset ptr, start_ptr

  end_ptr = ptr + end_pos[0]
  end_offset = tonumber (start_offset - 1) + C.g_utf8_pointer_to_offset start_ptr, end_ptr

  match, start_offset, end_offset

get_captures = (match_info, ptr, matches, start, count, offset = 0) ->
  for i = start, count - 1
    match, start_pos, end_pos = get_capture match_info, i, ptr
    matches[#matches + 1] = #match > 0 and match or start_pos + offset

properties = {
  pattern: => ffi.string C.g_regex_get_pattern self
  capture_count: => C.g_regex_get_capture_count self
}

methods = {

  match: (s, init = 1) =>
    match_info, ptr, count = do_match self, s, init
    return nil unless match_info

    matches = {}
    start = count > 1 and 1 or 0
    get_captures match_info, ptr, matches, start, count
    free_match_info match_info
    return table.unpack matches

  find: (s, init = 1) =>
    match_info, ptr, count = do_match self, s, init
    return nil unless match_info

    match, start_pos, end_pos = get_capture match_info, 0, ptr, true
    matches = { start_pos, end_pos }
    get_captures match_info, ptr, matches, 1, count
    free_match_info match_info
    return table.unpack matches

  gmatch: (s) =>
    return nil unless #s > 0
    ptr = const_char_p s
    start_pos = ffi.new 'gint[1]'
    mi = ffi.new 'GMatchInfo *[1]'
    matches = {}
    pos_matches = {}

    C.g_regex_match self, ptr, 0, mi

    while C.g_match_info_matches(mi[0]) != 0
      count = C.g_match_info_get_match_count mi[0]
      capture_start = count > 1 and 1 or 0
      capture_table = count > 2 and {} or matches

      for i = capture_start, count - 1
        match = get_capture_string mi, i

        if #match == 0 -- position capture
          if C.g_match_info_fetch_pos(mi[0], i, start_pos, null) == 0
            error 'Failed to fetch match position'

          index = #pos_matches + 1
          pos_matches[index] = tonumber(start_pos[0]) + 1
          match = index

        capture_table[#capture_table + 1] = match

      matches[#matches + 1] = capture_table if matches != capture_table
      C.g_match_info_next mi[0], nil

    free_match_info mi
    has_position_captures = #pos_matches > 0
    pos_matches = s\char_offset pos_matches if has_position_captures

    pos = 0
    ->
      pos += 1
      match = matches[pos]
      return nil unless match
      if type(match) == 'table'
        if has_position_captures
          for i, value in ipairs match
            match[i] = pos_matches[value] if type(value) == 'number'

        return table.unpack match
      else
        return type(match) == 'number' and pos_matches[match] or match

}

regex = ffi.typeof 'GRegex'

ffi.metatype regex, {
  __index: (k) =>
    return methods[k] if methods[k]
    return properties[k] self if properties[k]

  __tostring: => @pattern
}

r = (pattern) ->
  return pattern if ffi.istype regex, pattern

  err = ffi.new 'GError *[1]'
  regex = C.g_regex_new const_char_p(pattern), 0, 0, err

  if err[0] != nil
    err_s = ffi.string err[0].message
    code = err[0].code
    error "#{err_s} (code: #{code})", 2

  ffi.gc regex, C.g_regex_unref
  return regex

return setmetatable {
  escape: (s) ->
    ptr = C.g_regex_escape_string(s, #s)
    escaped = ffi.string ptr
    C.g_free ptr
    escaped

  is_instance: (v) -> ffi.istype regex, v
}, {
  __call: (...) => r ...
}