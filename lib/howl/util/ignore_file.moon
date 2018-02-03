append = table.insert

line_to_rule = (line) ->
  pattern = line.stripped

  -- our answer status, with negation handling
  status = true
  if pattern\sub(1, 1) == '!'
    pattern = pattern\sub(2)
    status = false

  -- escape pattern matching sensitive characters
  pattern = pattern\gsub '[]\\.[]', (c) -> "\\#{c}"

  -- normalize ignore pattern escapes
  pattern = pattern\gsub '\\\\(.)', (c) -> c

  if pattern\find('/', 2, true) -- non-leading separator included, sub path spec
    -- handle globs correctly
    pattern = pattern\gsub '%*+', (glob) ->
      #glob == 1 and '[^/]*' or glob

    if pattern\ends_with('/**')
      pattern = "#{pattern\sub(1, -3)}.+"

    if pattern\find('/**/', 1, true)
      pattern = pattern\gsub('/%*%*/', '/([^/]+/)*')

    if pattern\starts_with('**/')
      pattern = ".*(^|/)#{pattern\sub(4)}"
    else
       -- remove any leading slash
      if pattern\sub(1, 1) == '/'
        pattern = pattern\sub(2)

      pattern = "^#{pattern}"

  else -- shell glob or plain
    pattern = pattern\gsub '%*+', (glob) ->
      #glob == 1 and '.*' or glob\gsub('%*', '\\*')

    -- leading slash = anchor rest at first level
    if pattern\sub(1, 1) == '/'
      pattern = "^#{pattern\sub(2)}"
    else -- beginning or in sub dir
      pattern = "(^|/)#{pattern}"

  pattern: r("#{pattern}/?$"), :status

load_rules = (file) ->
  content = file.contents
  irrelevant = (line) -> line.is_blank or line\match '^%s*#'
  lines = [l for l in content\gmatch '[^\r\n]+' when not irrelevant(l)]
  [line_to_rule(l) for l in *lines]

matcher = (dir, file) ->
  return nil unless file.exists
  rules = load_rules(file)
  f_dir = file.parent
  path_mod = if dir == f_dir
    nil
  elseif dir\is_below(f_dir)
    relative = dir\relative_to_parent(f_dir)
    (p) -> "#{relative}/#{p}"
  elseif f_dir\is_below(dir)
    relative = f_dir\relative_to_parent(dir)
    (p) -> p\gsub("^#{relative}/", '')
  else
    error "ignore file '#{file}' outside of matching scope '#{dir}'"

  (path) ->
    path = path_mod(path) if path_mod

    -- we match rules in reverse order, since the last match takes precedence
    for i = #rules, 1, -1
      rule = rules[i]
      if rule.pattern\test(path)
        return rule.status and 'reject' or 'allow'

eval_matchers = (matchers, path) ->
  for m in *matchers
    ret = m path
    if ret == 'allow'
      return false

    if ret == 'reject'
      return true

  nil

class Evaluator
  new: (@dir, opts) =>
    @root_matchers = {}
    @matcher_cache = {}
    @ignore_files = opts.ignore_files or {'.ignore', '.gitignore'}

    -- add ignores for the root and parents
    d = dir
    while d
      for f in *@ignore_files
        file = d\join(f)
        if file.exists
          m = matcher(dir, file)
          @root_matchers[#@root_matchers + 1] = m
          @matcher_cache[file.parent.path] = m

      d = d.parent

  reject: (path) =>
    sub_matchers = @_get_sub_matchers path
    res = eval_matchers sub_matchers, path
    return res if res != nil
    res = eval_matchers @root_matchers, path
    res != nil and res or false

  _get_sub_matchers: (path) =>
    -- get any sub-ignore files for the path
    dir = path\match '(.+)/[^/]+$'
    return {} unless dir
    dir_matchers = @matcher_cache[dir]
    return dir_matchers if dir_matchers

    matchers = {}
    d = dir
    while d
      dir_matchers = @matcher_cache[d]
      if dir_matchers
        if #matchers > 0
          for m in *dir_matchers
            append matchers, m
        else
          matchers = dir_matchers

        break
      else
        for f in *@ignore_files
          file = @dir\join(d, f)
          m = matcher(@dir, file)
          if m
            append matchers, m
            @matcher_cache[file.path] = m

      d = d\match '(.+)/[^/]+$'

    @matcher_cache[dir] = matchers
    matchers

setmetatable {
  evaluator: (dir, opts = {}) ->
    eval = Evaluator dir, opts
    (path) -> eval\reject path
}, {
  -- ignore_file(file [, dir])
  __call: (file, dir = nil) =>
    unless file.exists
      error "#{file} does not exist"

    dir or= file.parent
    matchers = { matcher(dir, file) }

    setmetatable {
      :file
      :dir
    }, __call: (path) =>
      res = eval_matchers matchers, path
      res and true or false
}
