{:config, :activities} = howl
{:Process} = howl.io

class Git
  new: (root) =>
    @root = root
    @name = 'Git'

  paths: =>
    p = @_get_process "ls-files",
      "--exclude-standard",
      "--others",
      "--cached",
      "--directory"

    status = "$ #{p.command_line}"
    activities.run {
      title: "Reading Git paths from '#{@root}'",
      status: -> status,
    }, ->
      out_lines, err_lines = p\pump_lines!
      unless p.successful
        error "(git in '#{@root}'): #{table.concat(err_lines, '\n')}"

      [l for l in *out_lines when not l\ends_with('/')]

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
