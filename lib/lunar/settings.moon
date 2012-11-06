import File from lunar.fs

default_dir = ->
  home = os.getenv('HOME')
  home and File(home)\join('.lunar') or nil

class Settings

  new: (dir = default_dir!) =>
    unless dir.exists
      if dir.parent.exists
        dir\mkdir!
      else
        return

    @dir = dir

  load_user: =>
    return unless @dir
    for ext in *{ 'moon', 'lua' }
      init = @dir\join "init.#{ext}"
      if init.exists
        status, ret = pcall loadfile init
        unless status
          log.error "Error loading #{init}: #{ret}"
        break
