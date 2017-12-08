{:config, :activities} = howl
{:File, :Process} = howl.io
TYPE_REGULAR = File.TYPE_REGULAR

class Git
  new: (root) =>
    @root = root
    @name = 'Git'

  files: =>
    p = @_get_process "ls-files",
      "--exclude-standard",
      "--others",
      "--cached",
      "--directory"

    status = "$ #{p.command_line}"
    activities.run {
      title: "Reading Git entries from '#{@root}'",
      status: -> status,
    }, ->
      out_lines, err_lines = p\pump_lines!
      unless p.successful
        error "(git in '#{@root}'): #{table.concat(err_lines, '\n')}"

      status = "Loading files from Git entries"
      groot = @root.gfile
      return for i = 1, #out_lines
        activities.yield! if i % 1000 == 0
        line = out_lines[i]
        continue if line\ends_with('/')
        gfile = groot\get_child(line)
        File gfile, nil, type: TYPE_REGULAR

  diff: (file) =>
    p = @_get_process 'diff', file
    out, err = activities.run_process {
      title: "Loading Git diff for '#{file}'"
    }, p
    unless p.successful
      error "(git diff for '#{file}'): #{err or 'Failed to execute'}"

    not out.is_blank and out or nil

  run: (...) =>
    p = @_get_process ...
    stdout, stderr = p\pump!
    unless p.successful
      error "(git in '#{@root}'): #{stderr or 'Failed to execute'}"

    stdout

  _get_process: (...) =>
    exec_path = config.git_path or 'git'
    argv = { exec_path, ... }
    Process {
      cmd: argv,
      working_directory: @root,
      read_stdout: true,
      read_stderr: true,
    }
