ffi = require 'ffi'

import GError, gint from howl.cdefs
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
  gchar *   g_match_info_fetch          (const GMatchInfo *match_info, gint match_num);
  void      g_match_info_unref          (GMatchInfo *match_info);
  gboolean  g_match_info_fetch_pos      (const GMatchInfo *match_info,
                                         gint match_num,
                                         gint *start_pos,
                                         gint *end_pos);
]]

properties = {
  pattern: => ffi.string C.g_regex_get_pattern self
  capture_count: => C.g_regex_get_capture_count self
}

methods = {

  match: (s, init = 1) =>
    s = u s
    s = s\sub init unless init == 1
    mi = ffi.new 'GMatchInfo *[1]'
    matched = C.g_regex_match self, s.ptr, 0, mi
    matches = {}
    if matched != 0
      count = C.g_match_info_get_match_count mi[0]
      start = count > 1 and 1 or 0
      for i = start, count - 1
        s_match = C.g_match_info_fetch(mi[0], i)
        error "Failed to fetch capture #{i}" if s_match == nil
        match = u s_match

        if #match == 0
          start_pos = ffi.new 'gint[1]'
          if C.g_match_info_fetch_pos(mi[0], i, start_pos, nil) != 0
            pos_ptr = s.ptr + start_pos[0]
            char_offset = C.g_utf8_pointer_to_offset s.ptr, pos_ptr
            match = tonumber char_offset + 1

        append matches, match

    C.g_match_info_unref mi[0]
    return nil unless #matches > 0
    return table.unpack matches
}

regex = ffi.typeof 'GRegex'

ffi.metatype regex, {
  __index: (k) =>
    return methods[k] if methods[k]
    return properties[k] self if properties[k]
}

r = (pattern) ->
  return pattern if ffi.istype regex, pattern

  pattern = u pattern
  err = ffi.new 'GError *[1]'
  regex = C.g_regex_new pattern.ptr, 0, 0, err

  if err[0] != nil
    err_s = ffi.string err[0].message
    code = err[0].code
    error "#{err_s} (code: #{code})", 2

  ffi.gc regex, C.g_regex_unref
  return regex

escape = (s) ->
  u C.g_regex_escape_string(s, s.size or #s)

return setmetatable {
  :escape
}, {
  __call: (...) => r ...
}