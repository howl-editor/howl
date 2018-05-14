import config, VC from howl

find = (file) ->
  unless howl.sys.find_executable config.hg_path
    return nil

  while file != nil
    hg_dir = file\join('.hg')
    if hg_dir.exists
      return bundle_load('hg') file, hg_dir
    file = file.parent
  nil

VC.register 'hg', :find
config.define {
  name: 'hg_path',
  description: 'Path to hg executable',
  default: 'hg',
  scope: 'global'
}

info = {
  author: 'The Howl Developers',
  description: 'Hg bundle',
  license: 'MIT',
}

unload = ->
  VC.unregister 'hg'

return :info, :unload
