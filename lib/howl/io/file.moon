-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

core = require 'ljglibs.core'
GFile = require 'ljglibs.gio.file'
GFileInfo = require 'ljglibs.gio.file_info'
glib = require 'ljglibs.glib'
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
    res = path\gsub "~#{File.separator}", File.home_dir.path .. File.separator
    res

  separator: jit.os == 'Windows' and '\\' or '/'

  new: (target, cwd) =>
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

    super!

  @property basename: get: => @gfile.basename
  @property display_name: get: =>
    base = @basename
    @is_directory and "#{base}#{File.separator}" or base

  @property extension: get: => @basename\match('%.([^.]+)$')
  @property uri: get: => @gfile.uri
  @property is_directory: get: => @exists and @_file_type == GFileInfo.TYPE_DIRECTORY
  @property is_link: get: => @exists and @_file_type == GFileInfo.TYPE_SYMBOLIC_LINK
  @property is_special: get: => @exists and @_file_type == GFileInfo.TYPE_SPECIAL
  @property is_regular: get: => @exists and @_file_type == GFileInfo.TYPE_REGULAR
  @property is_mountable: get: => @exists and @_file_type == GFileInfo.TYPE_MOUNTABLE
  @property is_hidden: get: => @exists and @_info!.is_hidden
  @property is_backup: get: => @exists and @_info!.is_backup
  @property size: get: => @_info!.size
  @property exists: get: => @gfile.exists
  @property readable: get: => @exists and @_info('access')\get_attribute_boolean 'access::can-read'
  @property etag: get: => @exists and @_info('etag').etag
  @property modified_at: get: => @exists and @_info('time')\get_attribute_uint64 'time::modified'
  @property short_path: get: => @path\gsub "^#{File.home_dir.path}", '~'

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
      files = {}
      enum = @gfile\enumerate_children 'standard::name', GFile.QUERY_INFO_NONE
      while true
        info = enum\next_file!
        unless info
          enum\close!
          return files

        append files, File @gfile\get_child info.name

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

    local deadline
    if options.timeout
      deadline = glib.get_monotonic_time! + (1000 * 1000 * options.timeout)

    while dir
      if deadline and glib.get_monotonic_time! >= deadline
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

  copy: (dest, flags) =>
    bitflags = core.parse_flags 'G_FILE_', flags
    @gfile\copy File(dest).gfile, bitflags, nil, nil

  tostring: => tostring @path or @uri

  _info: (namespace) =>
    if namespace
      namespace = namespace .. '::*'
    else
      namespace = 'standard::*'

    @gfile\query_info namespace, GFile.QUERY_INFO_NONE

  @property _file_type: get: =>
    @ft or= @_info!.filetype
    @ft

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
