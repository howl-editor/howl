{:File} = howl.io
sys = howl.sys

version_file_for = (file) ->
  dir = file.is_directory and file or file.parent
  while dir
    version_file = dir\join('.ruby-version')

    return version_file if version_file.exists
    dir = dir.parent

rvm_ruby = (version) ->
  for rvm_dir in *{
    File(sys.env.HOME)\join('.rvm'),
    File('/usr/local/rvm'),
  }
    wrappers = rvm_dir\join('wrappers')
    if wrappers.exists
      for c in *wrappers.children
        if c.basename\find version
          return c\join('ruby').path

ruby_version_for = (file) ->
  version_file = version_file_for file
  return nil unless version_file

  version_file.contents.stripped

ruby_command_for = (path) ->
  version = path and ruby_version_for(path)
  if version
    cmd = rvm_ruby(version)
    return cmd if cmd

  cmd = sys.find_executable 'ruby'
  cmd or rvm_ruby('default')

:ruby_version_for, :ruby_command_for
