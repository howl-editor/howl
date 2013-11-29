import config from howl

run_in = (root, ...) ->
  exec_path = config.git_path or 'git'
  args = [tostring(s) for s in *{...}]
  cmd = table.concat { "cd '#{root}' &&", exec_path }, ' '
  cmd ..= ' ' .. table.concat args, ' '
  pipe = assert io.popen cmd
  chunk = assert pipe\read '*a'
  pipe\close!
  chunk

class Git
  new: (root, git_dir) =>
    @root = root
    @git_dir = git_dir

  files: =>
    output = run_in @root,
      "ls-files",
      "--exclude-standard",
      "--others",
      "--cached",
      "--directory"

    git_files = {}
    for path in output\gmatch '[^\n]+'
      file = @root\join path
      append git_files, file if file.exists
    git_files

  diff: (file) =>
    d = run_in @root, 'diff', file
    not d.blank and d or nil
