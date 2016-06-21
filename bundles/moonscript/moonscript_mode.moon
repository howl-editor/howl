-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)
append = table.insert
{:Project, :app} = howl
{:sandbox} = howl.aux

project_lint_config = (root) ->
  for p in *{'lint_config.moon', 'lint_config.lua'}
    config = root\join(p)
    return config if config.exists

load_lint_whitelist = (root, config, for_file, lint) ->
  cfg, err = loadfile config
  unless cfg
    log.error "Failed to load lint config from '#{config}': #{err}"
    return lint.default_whitelist

  s_box = sandbox no_globals: true
  wl = s_box -> cfg!.whitelist_globals
  return lint.default_whitelist unless wl

  whitelist = setmetatable {}, __index: lint.default_whitelist
  rel_path = for_file\relative_to_parent root
  for pattern, list in pairs wl
    if rel_path\match(pattern)
      for symbol in *list
        whitelist[symbol] = true

  whitelist

load_project_lint_whitelist = (root, for_file, lint) ->
  lint_config = project_lint_config root
  return lint.default_whitelist unless lint_config
  load_lint_whitelist root, lint_config, for_file, lint

class MoonscriptMode
  new: =>
    @lexer = bundle_load('moonscript_lexer')
    @inspectors = { self\inspect }
    with howl.mode.by_name('lua')
      @api = .api
      @completers = .completers

  comment_syntax: '--'

  indentation: {
    more_after: {
      '[-=]>%s*$', -- fdecls
      '[([{:=]%s*$' -- hanging operators
      r'^\\s*\\b(class|switch|do|with|for|when)\\b', -- block starters
      { r'^\\s*\\b(elseif|if|while|unless)\\b', '%sthen%s*'}, -- conditionals
      '^%s*else%s*$',
      { '=%s*if%s', '%sthen%s*'} -- 'if' used as rvalue
    }

    same_after: {
      ',%s*$'
    }

    less_for: {
      authoritive: false
      r'^\\s*(else|\\})\\s*$',
      '^%s*[]})]',
      { '^%s*elseif%s', '%sthen%s*' }
    }
  }

  auto_pairs: {
    '(': ')'
    '[': ']'
    '{': '}'
    '"': '"'
    "'": "'"
  }

  code_blocks:
    multiline: {
      { '{%s*$', '^%s*}', '}'}
      { '%[%s*$', '^%s*%]', ']'}
      { '%(%s*$', '^%s*%)', ')'}
      { '%[%[%s*$', '^%s*%]%]', ']]'}
    }

  structure: (editor) =>
    lines = {}
    parents = {}
    prev_line = nil

    patterns = {
      '%s*class%s+%w'
      r'\\w\\s*[=:]\\s*(\\([^)]*\\))?\\s*[=-]>'
      r'(?:it|describe|context)\\(?\\s+[\'"].+->\\s*$'
    }

    for line in *editor.buffer.lines
      if prev_line
        if prev_line.indentation < line.indentation
          append parents, prev_line
        else
          parents = [l for l in *parents when l.indentation < line.indentation]

      prev_line = line if line and not line.is_blank

      for p in *patterns
        if line\umatch p
          for i = 1, #parents
            append lines, table.remove parents, 1

          append lines, line
          prev_line = nil
          break

    #lines > 0 and lines or self.parent.structure @, editor

  inspect: (buffer) =>
    lint = require "moonscript.cmd.lint"
    lint_whitelist = lint.default_whitelist

    if buffer.file
      project = Project.for_file buffer.file
      if project
        lint_whitelist = load_project_lint_whitelist project.root, buffer.file, lint
      elseif buffer.file\is_below(app.settings.dir)
        howl_lint_config = app.root_dir\join('lint_config.moon')
        lint_whitelist = load_lint_whitelist app.settings.dir, howl_lint_config, buffer.file, lint

    res, err = lint.lint_code buffer.text, buffer.title, lint_whitelist
    unless res
      if err and err\match '%[%d+%]'
        return {{
          line: tonumber(err\match('%[(%d+)%]'))
          message: "Syntax error: Failed to parse"
          type: 'error'
        }}
      return nil

    inspections = {}
    for nr, message in res\gmatch 'line (%d+): ([^\n\r]+)'
      inspection = {
        line: tonumber(nr)
        type: 'warning'
        :message
      }
      symbols = [s for s in message\gmatch "`([^`]+)`"]
      if #symbols == 1
        inspection.search = symbols[1]

      append inspections, inspection

    inspections
