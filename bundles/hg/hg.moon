-- support for the Mercurial (hg) SCM - see https://www.mercurial-scm.org/

import config from howl
Process = howl.io.Process
append = table.insert

class Hg
  new: (root, hg_dir) =>
    @root = root
    @hg_dir = hg_dir
    @name = 'Hg'

  files: =>
    output = @run 'status', '--no-status', '-acmu'

    hg_files = {}
    for path in output\gmatch '[^\n]+'
      file = @root\join path
      append hg_files, file if file.exists and not file.is_directory

    table.sort hg_files
    hg_files

  diff: (file) =>
    d = @run 'diff', '--git', file
    not d.is_blank and d or nil

  run: (...) =>
    exec_path = config.hg_path or 'hg'
    argv = { exec_path, ... }
    out, err, process = Process.execute argv, working_directory: @root
    error "(hg in '#{@root}'): #{err or 'Failed to execute'}" unless process.successful
    out
