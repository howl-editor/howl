GFile = lgi.Gio.File
import PropertyObject from lunar.aux.moon

class File extends PropertyObject

  tmpfile: ->
    file = File assert os.tmpname!
    file.touch if not file.exists
    file

  tmpdir: ->
    with File assert os.tmpname!
      \delete! if .exists
      \mkdir!

  is_absolute: (path) ->
    (path\match('^/') or path\match('^%a:\\\\')) != nil

  separator: jit.os == 'Windows' and '\\' or '/'

  new: (path) =>
    @gfile = if type(path) == 'string' then GFile.new_for_path path else path
    @path = @gfile\get_path!
    super!

  @property basename: get: => @gfile\get_basename!
  @property extension: get: => @basename\match('%.(%w+)$')
  @property uri: get: => @gfile\get_uri!
  @property is_directory: get: => @file_type == 'directory'
  @property is_link: get: => @file_type == 'symbolic_link'
  @property is_special: get: => @file_type == 'special'
  @property is_regular: get: => @file_type == 'regular'
  @property is_shortcut: get: => @file_type == 'shortcut'
  @property is_mountable: get: => @file_type == 'mountable'
  @property is_hidden: get: => @info\get_is_hidden!
  @property is_backup: get: => @info\get_is_backup!
  @property size: get: => @info\get_size!
  @property exists: get: => @gfile\query_exists!

  @property file_type: get: =>
    @ft = @ft or @info\get_file_type!\lower!
    @ft

  @property info: get: =>
    if not @f_info
      @f_info, err = @gfile\query_info 'standard::*', 'NONE'
      error(err) if not @f_info
    @f_info

  @property contents:
    get: => tostring @_assert @gfile\load_contents!
    set: (contents) =>
      with @_assert io.open @path, 'w'
        \write contents
        \close!

  @property parent:
    get: =>
      parent = @gfile\get_parent!
      return if parent then File(parent) else nil

  @property children:
    get: =>
      files = {}
      enum = @gfile\enumerate_children 'standard::name', 'NONE'
      while true
        info, err = enum\next_file!
        return files if not info and not err
        error(err) if not info
        append files, File @gfile\get_child info\get_name!

  join: (...) =>
    root = @gfile
    root = root\get_child(child) for child in *{...}
    File root

  relative_to_parent: (parent) =>
    parent.gfile\get_relative_path @gfile

  is_below: (dir) => @relative_to_parent(dir) != nil
  mkdir: => @_assert @gfile\make_directory!
  mkdir_p: => @_assert @gfile\make_directory_with_parents!
  delete: => @_assert @gfile\delete!
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

  tostring: => @path or @uri

  @meta {
    __tostring: => @tostring!

    __div: (op) => @join op

    __concat: (op1, op2) ->
      if op1.__class == File
        op1\join(op2)
      else
        tostring(op1) .. tostring(op2)

    __eq: (op1, op2) ->
      op1 = File op1 if getmetatable(op1) != getmetatable(op2)
      op1\tostring! == op2\tostring!
  }

  _assert: (...) =>
    status, msg = ...
    error @tostring! .. ' :' .. msg, 3 if not status
    ...

File.rm = File.delete
File.unlink = File.delete
File.rm_r = File.delete_all

return File
