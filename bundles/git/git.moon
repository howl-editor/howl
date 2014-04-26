import config from howl
append = table.insert

class Git
  new: (root, git_dir) =>
    @root = root
    @git_dir = git_dir

  files: =>
    output = @run "ls-files",
      "--exclude-standard",
      "--others",
      "--cached",
      "--directory"

    git_files = {}
    for path in output\gmatch '[^\n]+'
      file = @root\join path
      append git_files, file if file.exists and not file.is_directory

    git_files

  diff: (file) =>
    d = @run 'diff', file
    not d.is_blank and d or nil

  run: (...) =>
    exec_path = config.git_path or 'git'
    args = [tostring(s) for s in *{...}]
    cmd = table.concat { "cd '#{@root}' &&", exec_path }, ' '
    cmd ..= ' ' .. table.concat args, ' '
    pipe = assert io.popen "sh -c '#{cmd}' 2>&1"
    chunk = assert pipe\read '*a'
    assert pipe\close!
    chunk
