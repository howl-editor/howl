-- Copyright 2018 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

{:activities, :config, :io, :sys} = howl
{:File, :Process, :process_output} = io
ffi = require 'ffi'

{:max, :min} = math
{string: ffi_string} = ffi
append = table.insert
file_sep = File.separator
searchers = {}

MAX_MESSAGE_LENGTH = 150

run_search_command = (process, directory, query, searcher) ->
  out, err = activities.run_process {
    title: "Searching for '#{query}' in '#{directory}' (using #{searcher.name})"
  }, process

  unless process.exited_normally
    error "#{process.exit_status_string}: #{err}"

  if process.successful
    process_output.parse out, {
      :directory,
      max_message_length: MAX_MESSAGE_LENGTH
    }
  else
    {}

load_searcher = (name, directory) ->
  searcher = searchers[name]
  error "Unknown searcher '#{name}'" unless searcher
  if searcher.is_available
    available, err = searcher.is_available(directory)
    error "Searcher '#{name}' unavailable (#{err})" unless available
  searcher

get_searcher_for = (directory) ->
  cfg = config.for_file directory
  sel = cfg.file_searcher
  local searcher

  if sel != 'auto'
    searcher = load_searcher sel, directory
  else
    candidates = {'rg', 'ag', 'native'}
    for candidate in *candidates
      s = searchers[candidate]
      if not s or (s.is_available and not s.is_available(directory))
        continue

      searcher = s
      break

    unless searcher
      error "No searcher available (tried #{table.concat(candidates, ',')})"

  searcher

prepare_direct_results = (searcher, directory, results) ->
  for r in *results
    unless r.path
      error "Misbehaving searcher '#{searcher.name}': Missing .path in result"

    unless r.line_nr
      error "Misbehaving searcher '#{searcher.name}': Missing .line_nr in result"

    unless r.message
      error "Misbehaving searcher '#{searcher.name}': Missing .message in result"

    r.file = directory\join(r.path) unless r.file

search = (directory, what, opts = {}) ->
  searcher = if type(opts.searcher) == 'string'
    load_searcher(opts.searcher, directory)
  else
    opts.searcher

  searcher or= get_searcher_for directory
  res = searcher.handler directory, what, {
    whole_word: opts.whole_word or false,
    max_message_length: MAX_MESSAGE_LENGTH
  }
  t = typeof res
  if t == 'Process'
    res = run_search_command res, directory, what, searcher
  elseif t == 'string'
    p = Process.open_pipe res, working_directory: directory
    res = run_search_command p, directory, what, searcher
  else
    prepare_direct_results searcher, directory, res

  res, searcher

sort = (matches, directory, term, context) ->
  activities.run {
    title: "Sorting '#{#matches}' search matches",
    status: -> "Sorting..",
  }, ->
    standalone_p, basename_search_p = if r'^\\p{L}+$'
      r"\\b#{term}\\b", r"\\b#{term}\\b[^#{file_sep}]*$"

    test_suffix_p = r'[_-](?:spec|test)\\.\\w+$'
    test_prefix_p = r"(?:^|#{file_sep})test_[^#{file_sep}]+$"
    path_split_p = "[^#{file_sep}]+"
    path_split = (p) -> [m for m in p\gmatch path_split_p]

    local rel_path
    cur_segments = if context
      file = context.buffer.file
      if file
        rel_path = file\relative_to_parent directory
        path_split rel_path

    name_cluster_p = if rel_path
      base = rel_path\umatch r'(.+?)(?:[_-](spec|test))?\\.\\w+$'
      "#{base}[._-]"

    scores = {}

    -- base score is 20, with higher being better
    for i = 1, #matches
      activities.yield! if i % 2000 == 0
      m = matches[i]
      continue if scores[m.path]

      score = 20

      if standalone_p and standalone_p\test(m.message)
        score += 3

      if cur_segments
        -- distance affects score, up to a 10 point difference
        m_segments = path_split m.path
        distance = 0
        for j = 1, max(#m_segments, #cur_segments)
          if cur_segments[j] != m_segments[j]
            distance += ((#m_segments - j) + (#cur_segments - j)) + 1
            break

        score -= min distance, 10

        -- check for same name cluster
        if name_cluster_p and #m_segments > 0
          if m_segments[#m_segments]\find name_cluster_p
            score += 4

      if basename_search_p and basename_search_p\test(m.path)
        score += 3

      if test_suffix_p\test(m.path) or test_prefix_p\test(m.path)
        score -= 2

      scores[m.path] = score

    sorted = [m for m in *matches]
    counter = 0
    table.sort sorted, (a, b) ->
      activities.yield! if counter % 3000 == 0
      counter += 1
      if a.path == b.path
        return a.line_nr < b.line_nr
      score_a, score_b = scores[a.path], scores[b.path]
      if score_a != score_b
        score_a > score_b
      else
        a.path > b.path

    sorted

register_searcher = (opts) ->
  for field in *{'name', 'description', 'handler'}
    error '`' .. field .. '` missing', 2 if not opts[field]

  searchers[opts.name] = opts

unregister_searcher = (name) ->
  searchers[name] = nil

config.define
  name: 'file_searcher'
  description: 'The searcher to use for searching files'
  type_of: 'string'
  default: 'auto'
  options: ->
    opts = [{name, opts.description} for name, opts in pairs searchers]
    table.insert opts, 1, {'auto', 'Pick an available searcher automatically'}
    opts

-- the silver searcher
config.define
  name: 'ag_executable'
  description: 'The silver searcher executable to use'
  default: 'ag'
  type_of: 'string'

register_searcher {
  name: 'ag'
  description: 'The Silver Searcher'

  is_available: (directory) ->
    cfg = config.for_file directory
    return true if sys.find_executable(cfg.ag_executable)
    false, "Executable 'ag' not found"

  handler: (directory, what, opts) ->
    cfg = config.for_file directory
    if opts.whole_word
      what = "\\b#{what}\\b"

    Process.open_pipe {
      cfg.ag_executable,
      '--nocolor',
      '--column',
      '-C', '0',
      '--nogroup',
      what
    }, working_directory: directory
}

-- ripgrep
config.define
  name: 'rg_executable'
  description: 'The ripgrep executable to use'
  default: 'rg'
  type_of: 'string'

register_searcher {
  name: 'rg'
  description: 'Ripgrep'

  is_available: (directory) ->
    cfg = config.for_file directory
    return true if sys.find_executable(cfg.rg_executable)
    false, "Executable 'rg' not found"

  handler: (directory, what, opts = {}) ->
    cfg = config.for_file directory
    if opts.whole_word
      what = "\\b#{what}\\b"

    Process.open_pipe {
      cfg.rg_executable,
      '--color', 'never',
      '--line-number',
      '--column',
      '--no-heading',
      '--max-columns', opts.max_message_length or 150
      what
    }, working_directory: directory
}

-- native searcher
native_paths = (dir) ->
  activities.run {
    title: "Reading paths for '#{dir}'",
    status: -> "Reading paths for '#{dir}'",
  }, ->
    ignore = howl.util.ignore_file.evaluator dir
    skip_exts = {ext, true for ext in *config.hidden_file_extensions}
    -- skip additional known binary extensions
    for ext in *{
      'gz',
      'tar',
      'tgz',
      'zip',
      'png',
      'jpg',
      'jpeg',
      'gif',
      'ttf',
      'woff',
      'eot',
      'otf'
    }
      skip_exts[ext] = true

    filter = (p) ->
      return true if p\ends_with('~')
      ext = p\match '%.(%w+)/?$'
      return true if skip_exts[ext]
      ignore p

    dir\find_paths exclude_directories: true, :filter

native_append_matches = (path, positions, mf, matches, max_message_length) ->
  contents = mf.contents
  upper = #mf - 1

  scan_to = (pos, start_pos, line) ->
    i = start_pos
    l_start_pos = start_pos
    pos = min pos, upper
    new_line = 0

    while i <= upper
      c = contents[i]
      if c == 10
        new_line = 1
      elseif c == 13
        new_line = 1
        if (i + 1) < upper and contents[i + 1] == 10
          new_line += 1

      if new_line > 0
        if pos <= i
          return line, l_start_pos, i - 1

        line += 1
        i += new_line
        l_start_pos = i
        new_line = 0
      else
        i += 1

    if pos <= i
      return line, l_start_pos, i - 1

    nil

  start_pos = 0
  line = 1
  for p in *positions
    continue if p < start_pos -- we've reported on this line already
    line, l_start_pos, l_end_pos = scan_to p, start_pos, line
    break unless line
    start_pos = l_end_pos
    len = l_end_pos - l_start_pos + 1
    if max_message_length
      len = min max_message_length, len

    append matches, {
      :path
      line_nr: line,
      column: (p - l_start_pos) + 1,
      message: ffi.string(contents + l_start_pos, max(len, 0))
    }

register_searcher {
  name: 'native'
  description: 'Naive but native Howl searcher'
  handler: (directory, what, opts = {}) ->
    MappedFile = require 'ljglibs.glib.mapped_file'
    GRegex = require 'ljglibs.glib.regex'
    p = what.ulower
    if opts.whole_word
      p = "\\b#{p}\\b"

    r = GRegex p, {'CASELESS', 'OPTIMIZE', 'RAW'}

    paths = native_paths directory
    dir_path = directory.path
    matches = {}
    count = 0
    activities.run {
      title: "Searching for '#{what}' in '#{directory}'",
      status: -> "Searched #{count} out of #{#paths} files..",
    }, ->
      for i = 1, #paths
        activities.yield! if i % 100 == 0
        p = paths[i]
        status, mf = pcall MappedFile, "#{dir_path}/#{p}"
        continue unless status
        contents = mf.contents
        continue unless contents and contents != nil
        unless ffi_string(contents, min(150, #mf)).is_likely_binary
          info = r\match_full_with_info contents, #mf, 0
          match_positions = {}
          if info
            while info\matches!
              start_pos = info\fetch_pos 0
              append match_positions, start_pos
              info\next!

            native_append_matches p, match_positions, mf, matches, opts.max_message_length

        mf\unref!
        count += 1

    matches
}

{
  :searchers
  :register_searcher
  :unregister_searcher
  :search
  :sort
}
