GFile = lgi.Gio.File

class File

  new: (path) =>
    @gfile = if type(path) == 'string' then GFile.new_for_path path else path

    with getmetatable(self)
      .__tostring = self.to_string
      .__div= self.join
      .__concat = (op1, op2) ->
        if getmetatable(op1) != getmetatable(self)
          op1 .. op2\to_string!
        else
          op1\join(op2)

  basename: => @gfile\get_basename!
  path: => @gfile\get_path!
  uri: => @gfile\get_uri!

  parent: =>
    parent = @gfile\get_parent!
    return if parent then File(parent) else nil

  join: (...) =>
    root = @gfile

    for child in *{...}
      root = root\get_child(child)

    return File(root)

  read_all: =>
    return tostring(@gfile\load_contents!)

  to_string: =>
    self\path! or self\uri!

return File
