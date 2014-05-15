import config from howl
Process = howl.io.Process
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
    argv = { exec_path, ... }
    out, err, process = Process.execute argv, working_directory: @root
    error "(git in '#{@root}'): #{err or 'Failed to execute'}" unless process.successful
    out
