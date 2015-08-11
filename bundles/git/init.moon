import config, VC from howl

find = (file) ->
  while file != nil
    git_dir = file\join('.git')
    if git_dir.exists
      return bundle_load('git') file, git_dir
    file = file.parent
  nil

VC.register 'git', :find
config.define name: 'git_path', description: 'Path to git executable'

info = {
  author: 'The Howl Developers',
  description: 'Git bundle',
  license: 'MIT',
}

unload = ->
  VC.unregister 'git'

return :info, :unload
