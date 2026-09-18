---
title: howl.io.http
---

# howl.io.http

## Overview

`howl.io.http` is an HTTP/1.1 client, supporting both `http` and `https`, with
no additional dependency to install.

Like [howl.io.Process](process.html), it provides the appearance and ease of use
of a synchronous API while being fully asynchronous underneath, so Howl stays
responsive while a request is in flight.

```moonscript
res = howl.io.http.get 'https://example.com/api/status'
if res.ok
  print res\json!.message
```

A response with a non-2xx status is returned like any other; it is not an error.
Failures that prevent a response from being obtained at all - a refused
connection, an unresolvable host, a TLS failure, a timeout, a malformed
response - raise instead. See [Errors](#errors).

_See also_:

- [howl.io.url](url.html) for URL parsing
- [howl.io.headers](headers.html) for the header collection returned by a response
- The [spec](../../spec/io/http_spec.html) for http

## Functions

### get (url, options = {})

Performs a `GET` request and returns a [Response](#response).

```moonscript
res = howl.io.http.get 'https://example.com/'
res = howl.io.http.get 'https://example.com/search', query: {q: 'howl', page: 2}
```

### post (url, body, options = {})

Performs a `POST` request and returns a [Response](#response).

`body` is either a string, which is sent as-is, or a table of body options -
`json`, `form` or `body` - which are merged into `options`:

```moonscript
-- a raw string body
res = howl.io.http.post url, 'raw payload'

-- JSON; sets Content-Type: application/json
res = howl.io.http.post url, json: {name: 'howl', tags: {'editor'}}

-- form encoding; sets Content-Type: application/x-www-form-urlencoded
res = howl.io.http.post url, form: {a: 1, b: 'x y'}
```

### head (url, options = {})

Performs a `HEAD` request and returns a [Response](#response). The response
carries headers but never a body.

### request (options)

The general form behind the above. `options.url` is required; everything else is
optional. See [Options](#options).

```moonscript
res = howl.io.http.request {
  url: 'https://example.com/things'
  method: 'PUT'
  headers: {Authorization: 'Bearer ...'}
  json: {name: 'howl'}
  timeout: 10
}
```

### download (url, target, options = {})

Downloads `url` to `target`, which is either a path string or a
[howl.io.File](file.html). The body is streamed straight to disk and never held
in memory, so this is what you want for anything large.

The content is written to `<target>.part` and renamed into place only once the
download has completed, so an interrupted download never leaves behind a file
that looks whole. The partial file is removed on failure.

```moonscript
res = howl.io.http.download 'https://example.com/bundle.tgz', '/tmp/bundle.tgz',
  on_progress: (received, total) -> print "#{received}/#{total or '?'}"

print res.file.path
```

Unlike the other functions, `download` raises for a non-2xx status rather than
returning it, since there is no useful file in that case. The returned response
has `body` set to `nil` and [file](#file) set to the target.

By default a download has no size limit; pass `max_size` to impose one.

## Options

All of the following are accepted by [request](#request-options), and by `get`, `post`,
`head` and `download` as their trailing `options` table.

| Option | Description |
| --- | --- |
| `url` | The URL to request. Required by [request](#request-options). Only `http` and `https` are accepted. |
| `method` | HTTP method. Defaults to `GET`. |
| `headers` | A table of request headers. See [Reserved headers](#reserved-headers). |
| `query` | A table appended to the URL as a query string, escaped for you. |
| `body` | A string body. |
| `json` | A value encoded as JSON, setting `Content-Type: application/json`. |
| `form` | A table encoded as a form body, setting `Content-Type: application/x-www-form-urlencoded`. |
| `timeout` | Seconds before the whole request is abandoned. Defaults to the `http_timeout` config variable. |
| `connect_timeout` | Seconds allowed for establishing the connection. Defaults to 10. |
| `max_redirects` | How many redirects to follow. `0` disables following entirely. Defaults to the `http_max_redirects` config variable. |
| `max_size` | Maximum accepted body size in bytes; `0` means no limit. Defaults to the `http_max_response_size` config variable, except for [download](#download-url-target-options). |
| `user_agent` | The `User-Agent` to send. Defaults to the `http_user_agent` config variable. |
| `proxy_enabled` | Whether to honour the system proxy configuration. Defaults to the `http_proxy_enabled` config variable. |
| `expect_success` | When true, a non-2xx status raises instead of being returned. |
| `on_progress` | Called as `(received, total)` as the body arrives. `total` is `nil` when the response has no `Content-Length`. |

Only one of `body`, `json` and `form` may be given.

## Response

[get](#get-url-options), [post](#post-url-body-options), [head](#head-url-options),
[request](#request-options) and [download](#download-url-target-options) all return a
response object.

### Properties

### status

The HTTP status code, as a number, e.g. `200`.

### status_text

The reason phrase, e.g. `'OK'`. May be an empty string; servers are not required
to send one.

### ok

True when [status](#status) is in the 2xx range.

### body

The response body as a string. `nil` for a
[download](#download-url-target-options), and empty for a response that cannot
carry a body, such as a `HEAD` request or a `204`.

### headers

The response headers, as a [howl.io.headers](headers.html) collection. Lookups
are case-insensitive:

```moonscript
res.headers['content-type']
res.headers['Content-Type']  -- the same thing
res.headers\all 'set-cookie' -- every value, for a repeated header
```

### content_type

The `Content-Type` with any parameters stripped, e.g. `'application/json'` for a
header of `application/json; charset=utf-8`. `nil` when the header is absent.

### content_length

The `Content-Length` as a number, or `nil` when the header is absent.

### http_version

The version from the status line, e.g. `'1.1'`.

### url

The URL the response actually came from. This differs from
[request_url](#request_url) when redirects were followed.

### request_url

The URL originally requested.

### redirects

A list of the URLs that redirected, in the order they were visited. Empty when
no redirect was followed.

### file

For a [download](#download-url-target-options), the
[howl.io.File](file.html) that was written. `nil` otherwise.

### Methods

### json ()

Decodes the body as JSON and returns the result. Raises if there is no body, or
if it does not parse.

### raise_for_status ()

Raises if [ok](#ok) is false, and returns the response otherwise, which makes it
convenient to chain:

```moonscript
data = howl.io.http.get(url)\raise_for_status!\json!
```

## Redirects

Redirects are followed for statuses 301, 302, 303, 307 and 308, up to
`max_redirects` hops. Exceeding the limit raises.

The method is rewritten the way every other client does it: a 303 always becomes
a `GET` with the body dropped, and so does a 301 or 302 on a `POST`. A 307 or
308 preserves both method and body. A relative `Location` is resolved against
the URL of the response carrying it.

Two rules exist to avoid leaking credentials or downgrading security, and both
raise rather than proceeding:

- A redirect from `https` to `http` is refused.
- A redirect to a scheme other than `http` or `https` is refused.

When a redirect crosses to a different origin - a change of scheme, host or port
- the `Authorization`, `Cookie` and `Proxy-Authorization` headers are dropped.

## TLS

Certificate validation is always on and cannot be disabled; there is
deliberately no "insecure" option. An invalid certificate raises an error naming
the URL and the reason reported by the TLS backend.

HTTPS requires a TLS backend (glib-networking) to be installed. When none is
present the request raises with a message saying so, rather than failing
obscurely.

## Errors

Anything that prevents a response from being obtained raises. This includes a
refused or interrupted connection, an unresolvable host, a TLS failure, a
timeout, a body exceeding `max_size`, too many redirects, and a response that
cannot be parsed. Error messages are prefixed with the URL concerned.

A non-2xx status is *not* an error - it is a perfectly good response that the
caller usually wants to inspect. Use [ok](#ok), `expect_success` or
[raise_for_status](#raise_for_status) when you would rather it raised.

Because errors are raised normally, `pcall` works as expected:

```moonscript
ok, res = pcall howl.io.http.get, url
unless ok
  log.error "fetch failed: #{res}"
```

## Reserved headers

`Host`, `Connection`, `Content-Length` and `Transfer-Encoding` are set by the
client, and passing them in `headers` raises - overriding them would either
break message framing or misrepresent the peer.

Header names and values are validated before a connection is opened. A name that
is not a valid token, or a value containing a carriage return, newline or NUL,
raises rather than being sent.

## Configuration

The following [config](../config.html) variables apply, all of them global:

| Variable | Default | Description |
| --- | --- | --- |
| `http_timeout` | `30` | Seconds before a request is abandoned. |
| `http_max_redirects` | `5` | How many redirects to follow before giving up. |
| `http_max_response_size` | `26214400` (25 MiB) | Maximum accepted body size; `0` for no limit. |
| `http_user_agent` | `'Howl'` | The `User-Agent` header sent with requests. |
| `http_proxy_enabled` | `true` | Whether requests honour the system proxy configuration. |

The proxy itself is not configured in Howl. `http_proxy_enabled` only controls
whether the system configuration is honoured; the settings come from the usual
`http_proxy`, `https_proxy` and `no_proxy` environment variables, and from the
desktop's proxy settings.

## Limitations

The following are deliberately not implemented:

- **Compression.** Requests are sent with `Accept-Encoding: identity`, and a
  response that arrives compressed anyway is refused rather than handed back as
  unreadable bytes.
- **Connection reuse.** Every request opens its own connection and sends
  `Connection: close`.
- **Cookies** and **authentication helpers.** Send an `Authorization` header
  yourself. Credentials embedded in a URL (`https://user:pass@host/`) are
  refused rather than silently transmitted.
