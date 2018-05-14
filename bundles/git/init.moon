{:config, :VC} = howl

find = (file) ->
  unless howl.sys.find_executable config.git_path
    return nil

  while file != nil
    git_dir = file\join('.git')
    if git_dir.exists
      return bundle_load('git') file
    file = file.parent
  nil

VC.register 'git', :find
config.define {
  name: 'git_path',
  description: 'Path to git executable',
  default: 'git',
  scope: 'global'
}

info = {
  author: 'The Howl Developers',
  description: 'Git bundle',
  license: 'MIT',
}

unload = ->
  VC.unregister 'git'

return :info, :unload
