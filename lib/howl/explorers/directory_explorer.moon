-- Copyright 2019 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

{:activities, :config} = howl
{:StyledText, :icon, :markup, :style} = howl.ui
{:File} = howl.io
{:PropertyObject} = howl.util.moon

append = table.insert
separator = howl.io.File.separator
current_dir_specifier = ".#{separator}"

howl.config.define
  name: 'file_icons'
  description: 'Whether file and directory icons are displayed'
  scope: 'global'
  type_of: 'boolean'
  default: true

style.define_default 'directory', 'key'
style.define_default 'filename', 'string'
icon.define_default 'directory', 'font-awesome-folder'
icon.define_default 'file', 'font-awesome-file'
icon.define_default 'file-new', 'font-awesome-plus-circle'

is_path_directory = (path) -> path[#path] == separator
path_demoted = (path) -> path[1] == '.' and path != current_dir_specifier  -- rename

hidden_exts = if howl.config.hidden_file_extensions
  {e, true for e in *howl.config.hidden_file_extensions}

path_hidden = (path) ->
  ext = path\match "%.(%w+)#{separator}-$"
  ext and hidden_exts[ext]

read_subtree = (d, opts={}) ->
  hidden_exts = {e, true for e in *howl.config.hidden_file_extensions}
  paths_found = 0
  cancel = false

  on_enter = (p, paths) ->
    paths_found = #paths
    return 'break' if cancel

  activities.run {
    title: "Scanning '#{d}'"
    status: -> "Reading entries (#{paths_found} paths collected).."
    cancel: -> cancel = true
  }, ->
    d\find_paths
      filter: path_hidden
      :on_enter
      exclude_non_directories: opts.directories_only
      max_depth: opts.max_depth

path_rank = (path) ->
  rank = 0
  unless path_demoted path
    rank += 2
  if is_path_directory path
    rank += 1
  return rank

sort_paths = (paths) ->
  table.sort paths, (a, b) ->
    a_rank = path_rank a
    b_rank = path_rank b
    return a < b if a_rank == b_rank
    return a_rank > b_rank

directory_lister = {
  list: (dir, opts={}) ->
    local paths, partial
    if opts.subtree
      paths, partial = read_subtree dir, directories_only: opts.directories_only
    else
      paths, partial = read_subtree dir, max_depth: 1, directories_only: opts.directories_only

    unless opts.files_only
      append paths, 1, current_dir_specifier

    if opts.sort
      sort_paths paths

    return paths, :partial

  find_hidden: (dir, sub_path) ->
    return unless path_hidden sub_path
    file = dir / sub_path
    relative_path = file\relative_to_parent dir
    if file.exists
      if file.is_directory
        return (relative_path .. separator), file
      return relative_path, file

  can_create: (dir, sub_path) ->
    file = dir / sub_path
    return true unless file.exists
}

dir_icon = icon.get('directory', 'directory')
file_icon = icon.get('file', 'filename')

display_row = (parent, path, with_icons=config.file_icons) ->
  tag = path_hidden(path) and StyledText('[hidden]', 'keyword') or ''
  is_directory = is_path_directory path
  d_name = StyledText(path, is_directory and 'directory' or 'filename')

  if with_icons
    used_icon = is_directory and dir_icon or file_icon
    { used_icon, d_name, tag, directory: parent, :path }
  else
    { d_name, tag, directory: parent, :path }


make_display_items = (paths, directory, opts={}) ->
  activities.run {
    title: "Loading paths for '#{opts.label or directory}'"
    status: -> "Preparing #{#paths} paths for selection.."
  }, ->
    with_icons = config.file_icons

    items = for i = 1, #paths
      activities.yield! if i % 1000 == 0
      path = paths[i]
      display_row directory, path, with_icons

    return items

class FileItem
  new: (@file) => @name = @file.basename

  display_row: => display_row @file.parent, @file.basename

  preview: => if config.preview_files return {
    file: @file
    line_nr: 1
  }

class DirectoryItem
  new: (@file) =>
    @name = @file.basename

  display_row: =>
    path = StyledText(@file.basename, 'filename') .. separator
    if config.file_icons
      {icon.get('file', 'filename'), path, ''}
    else
      {path, ''}

  preview: => text: tostring @file.path

class NewFile
  new: (@file, @relative_path) =>
    @new_file = true

  display_row: =>
    if config.file_icons
      {icon.get('file-new', 'keyword'), StyledText(@relative_path, 'keyword'), StyledText('[New]', 'keyword')}
    else
      {StyledText(@relative_path, 'keyword'), StyledText('[New]', 'keyword')}

  preview: => text: markup.howl "<comment>Create new file at #{@file.path}</>"


class DirectoryExplorer extends PropertyObject
  for_path: (path, opts={}) ->
    -- returns a list of Explorer objects for path and any unmatched text
    path = File.expand_path path
    file = File path
    trailing = path\match '/$'
    path = file.path .. (trailing or '')  -- normalize away '../'

    while file and not file.is_directory
      file = file.parent

    error "invalid path: #{path}" unless file

    under_root = (f) ->
      if opts.root
        return (opts.root == file or file\relative_to_parent opts.root)
      true

    unless under_root file
      file = opts.root
      error 'Cannot navigate above current root: ' .. opts.root, 0

    path_items = {}
    target_path = file.path
    opts = moon.copy opts
    -- some opts are shared among all explorers in the path
    opts.shared = {}
    opts.shared.show_subtree = opts.show_subtree

    while file
      append path_items, 1, DirectoryExplorer file, opts
      file = file.parent
      if opts.root  -- don't go above specified root
        if not under_root file
          break

    return path_items, path\sub #target_path + 2

  new: (@file=File.root_dir, opts={}) =>
    super!
    @lister =  opts.lister or directory_lister
    if opts.files_only and opts.directories_only
      error 'invalid to specify both files_only and directories_only'
    @files_only = opts.files_only
    @directories_only = opts.directories_only
    @allow_new = opts.allow_new
    @root = opts.root
    @name = @file.basename
    @shared_opts = opts.shared or {}

  _copy_opts: => {
    lister: @lister
    files_only: @files_only
    directories_only: @directories_only
    allow_new: @allow_new
    root: @root
    shared: @shared_opts
  }

  @property show_subtree:
    get: => @shared_opts.show_subtree
    set: (value) => @shared_opts.show_subtree = value

  display_title: =>
    if @show_subtree
      return @subtree_partial and 'Files (recursive, truncated)' or 'Files (recursive)'
    return 'Files'

  display_path: =>
    return StyledText(separator, 'directory') if @file.path == separator
    if @root
      relative_path = @file\relative_to_parent(@root)
      relative_path = if relative_path then relative_path .. separator else ''
      return StyledText(relative_path, 'directory')
    return StyledText(@file.short_path .. separator, 'directory')

  display_row: => display_row @file.parent, @file.basename .. separator

  preview: => title: @file.path, text: @file.path

  display_items: =>
    paths, opts = @lister.list(@file, sort:not @show_subtree, subtree: @show_subtree, directories_only: @directories_only, files_only: @files_only)
    @subtree_partial = opts.partial
    items = make_display_items paths, @file
    return items, {
      find_hidden: (sub_path) ->
        _, file  = @lister.find_hidden @file, sub_path
        if file
          if file.is_directory
            return DirectoryExplorer file, @_copy_opts!
          return FileItem file, true

        if @allow_new and @lister.can_create @file, sub_path
          return NewFile @file / sub_path, sub_path
    }

  get_item: (selection) =>
    return DirectoryItem @file if selection.path == current_dir_specifier

    if is_path_directory selection.path
      DirectoryExplorer (@file / selection.path), @_copy_opts!
    else
      FileItem @file / selection.path

  parse: (text) =>
    -- parse text as user types and jump directly to any directory specified
    return if @show_subtree  -- no text-only quick navigation for subtree mode
    return if text.is_blank or not text\contains File.separator

    unless @root
      -- direct jump to user home
      if text == '~'..File.separator
        return jump_to_absolute: DirectoryExplorer.for_path(File.home_dir.path, @_copy_opts!)
      if text == File.separator
        return jump_to_absolute: DirectoryExplorer.for_path(@file.root_dir.path, @_copy_opts!)

    local matched, remaining_text
    if text\starts_with File.separator
      -- parse absolute path
      matched, remaining_text  = DirectoryExplorer.for_path(text, @_copy_opts!)
    else
      -- parse path relative to current directory
      absolute_path = switch @file.path
        when File.separator then @file.path .. text  -- dont insert '/' for root
        else @file.path .. File.separator .. text
      matched, remaining_text = DirectoryExplorer.for_path(absolute_path, @_copy_opts!)
      -- dont just return the same diretory we're already in
      explorer = matched[#matched]
      return if explorer and explorer.file == @file

    if remaining_text.is_blank and not text\ends_with File.separator
      -- don't automatically enter directories unless text ends in separator
      remaining_text = matched[#matched].file.basename
      matched[#matched] = nil

    return jump_to_absolute: matched, text:remaining_text

  get_help: =>
    help = howl.ui.HelpContext!
    help\add_keys
      ctrl_s: 'Toggle recursive list'
    help\add_section
      heading: 'Navigation'
      text: 'Type <string>~/</> to jump to the home folder and <string>/</> to jump to the root folder.'
    if @allow_new
      help\add_section
        heading: 'Creating Files'
        text: 'Type a path that does not exist to specify a new file.'

    help

  actions: =>
    toggle_subtree:
      keystrokes: {'ctrl_s'}
      handler: (item) =>
        @show_subtree = not @show_subtree
