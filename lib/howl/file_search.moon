-- Copyright 2018 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

{:activities, :config, :io, :sys} = howl
{:File, :Process, :process_output} = io

{:max, :min} = math
file_sep = File.separator
searchers = {}

run_search_command = (process, directory, query) ->
  out, err = activities.run_process {
    title: "Searching for '#{query}' in '#{directory}'"
  }, process

  unless process.successful
    error "#{process.exit_status_string}: #{err}"

  process_output.parse out, :directory

get_searcher_for = (directory) ->
  cfg = config.for_file directory
  sel = cfg.file_searcher
  local searcher

  if sel != 'auto'
    searcher = searchers[sel]
    error "Unknown searcher '#{sel}'" unless searcher
    if searcher.is_available
      available, err = searcher.is_available(directory)
      error "Searcher '#{sel}' unavailable (#{err})" unless available
  else
    candidates = {'rg', 'ag'}
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
  searcher = get_searcher_for directory
  res = searcher.handler what, directory
  t = typeof res
  if t == 'Process'
    res = run_search_command res, directory, what
  elseif t == 'string'
    p = Process.open_pipe res, working_directory: directory
    res = run_search_command p, directory, what
  else
    prepare_direct_results searcher, directory, res

  res

sort = (matches, directory, term, context) ->
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
  for m in *matches
    continue if scores[m.path]

    score = 20

    if standalone_p and standalone_p\test(m.message)
      score += 3

    if cur_segments
      -- distance affects score, up to a 10 point difference
      m_segments = path_split m.path
      distance = 0
      for i = 1, max(#m_segments, #cur_segments)
        if cur_segments[i] != m_segments[i]
          distance += ((#m_segments - i) + (#cur_segments - i)) + 1
          break

      score -= min distance, 10

      -- check for same name cluster
      if name_cluster_p and #m_segments > 0
        if m_segments[#m_segments]\find name_cluster_p
          score += 4

    if basename_search_p and basename_search_p\test(m.path)
      score += 7

    if test_suffix_p\test(m.path) or test_prefix_p\test(m.path)
      score -= 2

    scores[m.path] = score

  sorted = [m for m in *matches]
  table.sort sorted, (a, b) -> scores[a.path] > scores[b.path]
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

-- the silver search

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

  handler: (what, directory) ->
    cfg = config.for_file directory
    Process.open_pipe {
      cfg.ag_executable,
      '--nocolor',
      '--column',
      '-C', '0',
      '--nogroup'
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

  handler: (what, directory) ->
    cfg = config.for_file directory
    Process.open_pipe {
      cfg.rg_executable,
      '--color', 'never',
      '--line-number',
      '--column',
      '--no-heading',
      what
    }, working_directory: directory
}

{
  :searchers
  :register_searcher
  :unregister_searcher
  :search
  :sort
}
