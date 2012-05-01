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

  self\property basename:
    get: => @gfile\get_basename!

  self\property extension:
    get: => self.basename\match('%.(%w+)$')

  self\property path:
    get: => @gfile\get_path!

  self\property uri:
    get: => @gfile\get_uri!

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
