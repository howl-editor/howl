-- Copyright 2012-2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE.md)

GFile = require 'ljglibs.gio.file'
GFileInfo = require 'ljglibs.gio.file_info'
glib = require 'ljglibs.glib'
import PropertyObject from howl.aux.moon
append = table.insert

home_dir = glib.get_home_dir!

class File extends PropertyObject

  tmpfile: ->
    file = File assert os.tmpname!
    file.touch if not file.exists
    file

  tmpdir: ->
    with File assert os.tmpname!
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
    res = path\gsub '~', home_dir
    res

  separator: jit.os == 'Windows' and '\\' or '/'

  new: (target) =>
    error "missing parameter #1 for File()", 3 unless target
    t = typeof target
    if t == 'File'
      @gfile = target.gfile
      @path = target.path
    else
      @gfile = if t == 'string' or t == 'ustring' then @gfile = GFile.new_for_path tostring(target) else target
      @path = @gfile.path

    super!

  @property basename: get: => @gfile.basename
  @property extension: get: => @basename\match('%.(%w+)$')
  @property uri: get: => @gfile.uri
  @property is_directory: get: => @file_type == GFileInfo.TYPE_DIRECTORY
  @property is_link: get: => @file_type == GFileInfo.TYPE_SYMBOLIC_LINK
  @property is_special: get: => @file_type == GFileInfo.TYPE_SPECIAL
  @property is_regular: get: => @file_type == GFileInfo.TYPE_REGULAR
  @property is_shortcut: get: => @file_type == GFileInfo.TYPE_SHORTCUT
  @property is_mountable: get: => @file_type == GFileInfo.TYPE_MOUNTABLE
  @property is_hidden: get: => @_info!.is_hidden
  @property is_backup: get: => @_info!.is_backup
  @property size: get: => @_info!.size
  @property exists: get: => @gfile.exists
  @property readable: get: => @exists and @_info('access')\get_attribute_boolean 'access::can-read'
  @property etag: get: => @exists and @_info('etag').etag
  @property modified_at: get: => @exists and @_info('time')\get_attribute_uint64 'time::modified'
  @property short_path: get: => @path\gsub "^#{home_dir}", '~'

  @property writeable: get: =>
    if @exists
      return @_info('access')\get_attribute_boolean 'access::can-write'
    else
      return @parent.exists and @parent.writeable

  @property file_type: get: =>
    @ft or= @_info!.filetype
    @ft

  @property contents:
    get: => @gfile\load_contents!
    set: (contents) =>
      with @_assert io.open @path, 'w'
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

  open: (func) =>
    fh = assert io.open @path

    if func
      ret = { pcall func, fh }
      fh\close!
      error ret[2] unless ret[1]
      return table.unpack ret, 2

    fh

  read: (...) =>
    args = {...}
    @open (fh) -> fh\read table.unpack args

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
    if options.name then append filters, (entry) -> not entry\tostring!\match options.name
    if options.filter then append filters, options.filter
    filter = (entry) -> for f in *filters do return true if f entry

    files = {}
    directories = {}
    dir = self
    while dir
      children = dir.children
      if options.sort then table.sort children, (a,b) -> a.basename < b.basename

      for entry in *children
        if entry.is_directory
          append directories, 1, entry
        else
          append files, entry if not filter entry

      dir = table.remove directories
      append(files, dir) if dir and not filter dir

    files

  tostring: => tostring @path or @uri

  _info: (namespace) =>
    if namespace
      namespace = namespace .. '::*'
    else
      namespace = 'standard::*'

    @gfile\query_info namespace, GFile.QUERY_INFO_NONE

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

File.__base.rm = File.delete
File.__base.unlink = File.delete
File.__base.rm_r = File.delete_all

return File
