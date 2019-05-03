-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

GFile = require 'ljglibs.gio.file'
GFileInfo = require 'ljglibs.gio.file_info'
glib = require 'ljglibs.glib'
{:park, :resume, :resume_with_error, :wait} = howl.dispatch
import PropertyObject from howl.util.moon
append = table.insert

file_types = {
  [tonumber GFileInfo.TYPE_DIRECTORY]: 'directory',
  [tonumber GFileInfo.TYPE_SYMBOLIC_LINK]: 'symlink',
  [tonumber GFileInfo.TYPE_SPECIAL]: 'special',
  [tonumber GFileInfo.TYPE_REGULAR]: 'regular',
  [tonumber GFileInfo.TYPE_MOUNTABLE]: 'mountable',
  [tonumber GFileInfo.TYPE_UNKNOWN]: 'unknown',
}

class File extends PropertyObject
  TYPE_DIRECTORY: GFileInfo.TYPE_DIRECTORY
  TYPE_SYMBOLIC_LINK: GFileInfo.TYPE_SYMBOLIC_LINK
  TYPE_SPECIAL: GFileInfo.TYPE_SPECIAL
  TYPE_REGULAR: GFileInfo.TYPE_REGULAR
  TYPE_MOUNTABLE: GFileInfo.TYPE_MOUNTABLE
  TYPE_UNKNOWN: GFileInfo.TYPE_UNKNOWN

  @async: false

  tmpfile: ->
    file = File assert os.tmpname!
    file.touch if not file.exists
    file

  tmpdir: ->
    with File os.tmpname!
      \delete! if .exists
      \mkdir!

  with_tmpfile: (f) ->
    file = File.tmpfile!
    status, err = pcall f, file
    file\delete_all! if file.exists
    error err if not status

  is_absolute: (path) ->
    (path\match('^/') or path\match('^%a:\\\\')) != nil

  expand_path: (path) ->
    expanded_home = File.home_dir.path .. File.separator
    res = path\gsub ".+#{File.separator}~#{File.separator}", expanded_home
    res\gsub "^~#{File.separator}", expanded_home

  separator: jit.os == 'Windows' and '\\' or '/'

  new: (target, cwd, opts) =>
    error "missing parameter #1 for File()", 3 unless target
    t = typeof target
    if t == 'File'
      @gfile = target.gfile
      @path = target.path
    else
      if t == 'string'
        if cwd and not self.is_absolute target
          target = GFile(tostring cwd)\get_child(target).path

        @gfile = GFile tostring target
      else
        @gfile = target

      @path = @gfile.path

    if opts
      @_ft = opts.type

    super!

  @property basename: get: => @gfile.basename
  @property display_name: get: =>
    base = @basename
    @is_directory and "#{base}#{File.separator}" or base

  @property extension: get: => @basename\match('%.([^.]+)$')
  @property uri: get: => @gfile.uri
  @property is_directory: get: => @_has_file_type GFileInfo.TYPE_DIRECTORY
  @property is_link: get: => @_has_file_type GFileInfo.TYPE_SYMBOLIC_LINK
  @property is_special: get: => @_has_file_type GFileInfo.TYPE_SPECIAL
  @property is_regular: get: => @_has_file_type GFileInfo.TYPE_REGULAR
  @property is_mountable: get: => @_has_file_type GFileInfo.TYPE_MOUNTABLE
  @property is_hidden: get: => @exists and @_info!.is_hidden
  @property is_backup: get: => @exists and @_info!.is_backup
  @property size: get: => @_info!.size
  @property exists: get: => @gfile.exists
  @property readable: get: => @exists and @_info('access')\get_attribute_boolean 'access::can-read'
  @property etag: get: => @exists and @_info('etag').etag
  @property modified_at: get: => @exists and @_info('time')\get_attribute_uint64 'time::modified'
  @property short_path: get: =>
    return "~" if @path == File.home_dir.path
    @path\gsub "^#{File.home_dir.path}#{File.separator}", '~/'

  @property root_dir:
    get: =>
      file = @
      while file.parent
        file = file.parent
      return file

  @property writeable: get: =>
    if @exists
      return @_info('access')\get_attribute_boolean 'access::can-write'
    else
      return @parent.exists and @parent.writeable

  @property file_type: get: => file_types[tonumber @_file_type]

  @property contents:
    get: => @gfile\load_contents!
    set: (contents) =>
      with @_assert io.open @path, 'wb'
        \write tostring contents
        \close!

  @property parent:
    get: =>
      parent = @gfile.parent
      return if parent then File(parent) else nil

  @property children:
    get: =>
      File.async and @children_async or @children_sync

  @property children_sync:
    get: =>
      files = {}
      enum = @gfile\enumerate_children 'standard::name,standard::type', GFile.QUERY_INFO_NONE
      while true
        info = enum\next_file!
        unless info
          enum\close!
          return files

        append files, File(enum\get_child(info), nil, type: info.filetype)

  @property children_async:
    get: =>
      handle = park 'enumerate-children-async'

      @gfile\enumerate_children_async 'standard::name,standard::type', nil, nil,  (status, ret, err_code) ->
        if status
          resume handle, ret
        else
          resume_with_error handle, "#{ret} (#{err_code})"

      enum = wait handle

      files = {}
      while true
        info = enum\next_file!
        unless info
          enum\close!
          return files

        append files, File(enum\get_child(info), nil, type: info.filetype)

  open: (mode = 'r', func) =>
    fh = assert io.open @path, mode

    if func
      ret = table.pack pcall func, fh
      fh\close!
      error ret[2] unless ret[1]
      return table.unpack ret, 2, ret.n

    fh

  read: (...) =>
    args = {...}
    @open 'r', (fh) -> fh\read table.unpack args

  join: (...) =>
    root = @gfile
    root = root\get_child(tostring child) for child in *{...}
    File root

  relative_to_parent: (parent) =>
    parent.gfile\get_relative_path @gfile

  is_below: (dir) => @relative_to_parent(dir) != nil
  mkdir: => @gfile\make_directory!
  mkdir_p: => @gfile\make_directory_with_parents!
  delete: => @gfile\delete!
  delete_all: =>
    if @is_directory
      entries = @find!
      entry\delete! for entry in *entries when not entry.is_directory
      directories = [f for f in *entries when f.is_directory]
      table.sort directories, (a,b) -> a.path > b.path
      dir\delete! for dir in *directories

    @delete!

  touch: => @contents = '' if not @exists

  find: (options = {}) =>
    error "Can't invoke find on a non-directory", 1 if not @is_directory

    filters = {}
    if options.filter then append filters, options.filter
    filter = (entry) -> for f in *filters do return true if f entry

    files = {}
    directories = {}
    dir = self

    on_enter = options.on_enter

    while dir
      if on_enter and 'break' == on_enter(dir, files)
        return files, true

      ok, children = pcall -> dir.children
      unless ok
        dir = table.remove directories
        append(files, dir) if dir
        continue

      if options.sort then table.sort children, (a,b) -> a.basename < b.basename

      for entry in *children
        continue if filter entry
        if entry.is_directory
          append directories, 1, entry
        else
          append files, entry

      dir = table.remove directories
      append(files, dir) if dir

    files, false

  find_paths: (opts = {}) =>
    separator = File.separator
    exclude_directories = opts.exclude_directories
    exclude_non_directories = opts.exclude_non_directories

    get_children = if File.async then
      (dir) ->
        handle = park 'enumerate-children-async'

        dir\enumerate_children_async 'standard::name,standard::type', nil, nil,  (status, ret, err_code) ->
          if status
            resume handle, ret
          else
            resume handle, nil

        wait handle
    else
      (dir) ->
        dir\enumerate_children 'standard::name,standard::type', GFile.QUERY_INFO_NONE

    filter = opts.filter
    on_enter = opts.on_enter

    scan_dir = (dir, base, list = {}, depth=1) ->
      return if opts.max_depth and depth > opts.max_depth
      enum = get_children dir
      return unless enum

      while true
        info = enum\next_file!
        unless info
          enum\close!
          break

        if info.filetype == GFileInfo.TYPE_DIRECTORY
          f = enum\get_child info
          path = "#{base}#{info.name}#{separator}"
          continue if filter and filter(path)
          if on_enter and 'break' == on_enter(path, list)
            return true

          append list, path unless exclude_directories
          scan_dir f, path, list, depth + 1
        else
          path = "#{base}#{info.name}"
          continue if filter and filter(path)
          append list, path unless exclude_non_directories

    error "Can't invoke find on a non-directory", 1 if not @is_directory
    paths = {}

    if on_enter and 'break' == on_enter(".#{separator}", paths)
      return paths, true

    partial = scan_dir GFile(@path), '', paths
    paths, partial

  copy: (dest, flags) =>
    @gfile\copy File(dest).gfile, flags, nil, nil

  tostring: => tostring @path or @uri

  _info: (namespace = 'standard') =>
    @gfile\query_info "#{namespace}::*", GFile.QUERY_INFO_NONE

  @property _file_type: get: =>
    @_ft or= @_info!.filetype
    @_ft

  _has_file_type: (t) =>
    return @_ft == t if @_ft != nil
    return false unless @exists
    @_ft = @_info!.filetype
    @_ft == t

  @meta {
    __tostring: => @tostring!

    __div: (op) => @join op

    __concat: (op1, op2) ->
      if op1.__class == File
        op1\join(op2)
      else
        tostring(op1) .. tostring(op2)

    __eq: (op1, op2) -> op1\tostring! == op2\tostring!
    __lt: (op1, op2) -> op1\tostring! < op2\tostring!
    __le: (op1, op2) -> op1\tostring! <= op2\tostring!
  }

  _assert: (...) =>
    status, msg = ...
    error @tostring! .. ': ' .. msg, 3 if not status
    ...

File.home_dir = File glib.get_home_dir!
File.__base.rm = File.delete
File.__base.unlink = File.delete
File.__base.rm_r = File.delete_all

return File
