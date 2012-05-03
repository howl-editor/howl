GFile = lgi.Gio.File
import PropertyObject from vilu.aux.moon

class File extends PropertyObject

  tmpfile: ->
    File os.tmpname!

  new: (path) =>
    super!
    @gfile = if type(path) == 'string' then GFile.new_for_path path else path

    with getmetatable(self)
      .__tostring = self.tostring
      .__div= self.join
      .__concat = (op1, op2) ->
        if getmetatable(op1) != getmetatable(self)
          op1 .. op2\tostring!
        else
          op1\join(op2)

  self\property basename: get: => @gfile\get_basename!
  self\property extension: get: => @basename\match('%.(%w+)$')
  self\property path: get: => @gfile\get_path!
  self\property uri: get: => @gfile\get_uri!
  self\property is_directory: get: => @file_type == 'directory'
  self\property is_link: get: => @file_type == 'symbolic_link'
  self\property is_special: get: => @file_type == 'special'
  self\property is_regular: get: => @file_type == 'regular'
  self\property is_shortcut: get: => @file_type == 'shortcut'
  self\property is_mountable: get: => @file_type == 'mountable'
  self\property is_hidden: get: => @info\get_is_hidden!
  self\property is_backup: get: => @info\get_is_backup!
  self\property size: get: => @info\get_size!
  self\property exists: get: => @gfile\query_exists!

  self\property file_type: get: =>
    @ft = @ft or @info\get_file_type!\lower!
    @ft

  self\property info: get: =>
    if not @f_info
      @f_info, err = @gfile\query_info 'standard::*', 'NONE'
      error(err) if not @f_info
    @f_info

  self\property contents:
    get: => tostring self\_assert @gfile\load_contents!
    set: (contents) =>
      with self\_assert io.open self.path, 'w'
        \write contents
        \close!

  self\property parent:
    get: =>
      parent = @gfile\get_parent!
      return if parent then File(parent) else nil

  self\property children:
    get: =>
      files = {}
      enum = @gfile\enumerate_children 'standard::name', 'NONE'
      while true
        info, err = enum\next_file!
        return files if not info and not err
        error(err) if not info
        table.insert files, File @gfile\get_child info\get_name!

  join: (...) =>
    root = @gfile

    for child in *{...}
      root = root\get_child(child)

    return File(root)

  delete: =>
    self\_assert @gfile\delete!

  tostring: => self.path or self.uri

  _assert: (...) =>
   status, msg = ...
   error self.path .. ' :' .. msg, 3 if not status
   ...

return File
