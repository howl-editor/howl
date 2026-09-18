-- Copyright 2026 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

-- URL parsing, built on GLib's GUri rather than a hand-written RFC 3986 parser.
-- GUri is already linked in (GTK 4 requires gio >= 2.84, well past GUri's 2.66)
-- and gets the fiddly parts - relative reference resolution above all - right.
--
-- parse() returns a plain Lua table with the GUri handle dropped, so everything
-- above this module stays FFI-free and easy to spec.

ffi = require 'ffi'
glib = require 'ljglibs.glib'
require 'ljglibs.cdefs.glib'

C = ffi.C
ffi_gc, ffi_string = ffi.gc, ffi.string
append = table.insert

DEFAULT_PORTS = {
  http: 80
  https: 443
}

-- G_URI_FLAGS_ENCODED (1 << 3) keeps path, query and userinfo percent-encoded.
-- Without it GUri hands back decoded values, and putting those straight into a
-- request line reintroduces the spaces and delimiters the escaping existed to
-- remove - a malformed request for any URL carrying an escape.
--
-- HAS_PASSWORD is deliberately not set: we do not send credentials from a URL.
PARSE_FLAGS = 8

str = (s) ->
  return nil if s == nil
  ffi_string s

-- GUri hands back the host without brackets ('::1', not '[::1]'). Anything that
-- reassembles a host - the Host header, an authority - has to put them back, so
-- the logic lives here once.
bracket = (host) ->
  return host unless host and host\find ':', 1, true
  "[#{host}]"

to_table = (uri, source) ->
  scheme = str(C.g_uri_get_scheme(uri))
  scheme = scheme and scheme\lower!
  host = str C.g_uri_get_host(uri)
  port = tonumber C.g_uri_get_port(uri)
  default_port = DEFAULT_PORTS[scheme]
  -- g_uri_get_port returns -1 when the URL carried no explicit port
  port = default_port if port == -1
  path = str(C.g_uri_get_path(uri))
  path = '/' if not path or path == ''
  query = str C.g_uri_get_query(uri)

  authority = bracket host
  if authority and port and port != default_port
    authority ..= ":#{port}"

  request_target = path
  request_target ..= "?#{query}" if query and query != ''

  {
    :scheme
    :host
    :port
    :path
    :query
    :default_port
    :authority
    :request_target
    userinfo: str C.g_uri_get_userinfo(uri)
    fragment: str C.g_uri_get_fragment(uri)
    -- what we hand to g_socket_client_connect_to_uri_async, and what a caller
    -- sees as res.url: normalised, with the fragment dropped since it is never
    -- sent to a server. A literal '#' elsewhere is percent-encoded by GUri, so
    -- the first one always delimits the fragment.
    url: source\match('^([^#]*)') or source
  }

-- Returns a GUri* with a finalizer attached, or nil plus a message.
parse_uri = (s) ->
  return nil, 'URL must be a string' unless type(s) == 'string'
  return nil, 'URL is empty' if s == ''

  status, ret = glib.get_error C.g_uri_parse, s, PARSE_FLAGS
  unless status
    return nil, "invalid URL '#{s}': #{ret}"

  return nil, "invalid URL '#{s}'" if ret == nil
  ffi_gc ret, C.g_uri_unref

parse = (s) ->
  uri, err = parse_uri s
  return nil, err unless uri

  normalised = str C.g_uri_to_string(uri)
  t = to_table uri, normalised or s
  return nil, "URL has no host: '#{s}'" unless t.host and t.host != ''
  t

-- Resolves a possibly-relative reference against a base URL. This is what makes
-- a relative 'Location:' header work, and is the main reason to use GUri.
resolve = (base, ref) ->
  return nil, 'relative reference must be a string' unless type(ref) == 'string'
  base_url = type(base) == 'table' and base.url or base
  base_uri, err = parse_uri base_url
  return nil, err unless base_uri

  status, ret = glib.get_error C.g_uri_parse_relative, base_uri, ref, PARSE_FLAGS
  unless status
    return nil, "invalid URL reference '#{ref}': #{ret}"
  return nil, "invalid URL reference '#{ref}'" if ret == nil

  uri = ffi_gc ret, C.g_uri_unref
  resolved = str C.g_uri_to_string(uri)
  t = to_table uri, resolved
  return nil, "resolved URL has no host: '#{ref}'" unless t.host and t.host != ''
  t

escape = (s, reserved = nil, allow_utf8 = true) ->
  ptr = C.g_uri_escape_string tostring(s), reserved, allow_utf8
  return '' if ptr == nil
  glib.g_string ptr

unescape = (s) ->
  ptr = C.g_uri_unescape_string tostring(s), nil
  return nil if ptr == nil
  glib.g_string ptr

-- Keys are sorted so a generated query string is deterministic, which matters
-- for specs and for anything that caches on the URL.
build_query = (params) ->
  keys = [k for k in pairs params]
  table.sort keys, (a, b) -> tostring(a) < tostring(b)

  parts = {}
  for key in *keys
    value = params[key]
    if type(value) == 'table'
      for v in *value
        append parts, "#{escape tostring(key)}=#{escape tostring(v)}"
    else
      append parts, "#{escape tostring(key)}=#{escape tostring(value)}"

  table.concat parts, '&'

{
  :parse
  :resolve
  :escape
  :unescape
  :build_query
  :bracket
  :DEFAULT_PORTS
}
