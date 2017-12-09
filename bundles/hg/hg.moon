-- support for the Mercurial (hg) SCM - see https://www.mercurial-scm.org/

{:activities, :config} = howl
{:Process} = howl.io

class Hg
  new: (root, hg_dir) =>
    @root = root
    @hg_dir = hg_dir
    @name = 'Hg'

  paths: =>
    p = @_get_process 'status', '--no-status', '-acmu'
    activities.run {
      title: "Reading Hg entries from '#{@root}'",
      status: -> "$ #{p.command_line}",
    }, ->
      out_lines, err_lines = p\pump_lines!
      unless p.successful
        error "(hg in '#{@root}'): #{table.concat(err_lines, '\n')}"
      out_lines

  diff: (file) =>
    p = @_get_process 'diff', '--git', file
    out, err = activities.run_process {
      title: "Loading Hg diff for '#{file}'"
    }, p
    unless p.successful
      error "(hg diff for '#{file}'): #{err or 'Failed to execute'}"

    not out.is_blank and out or nil

  run: (...) =>
    p = @_get_process ...
    stdout, stderr = p\pump!
    unless p.successful
      error "(hg in '#{@root}'): #{stderr or 'Failed to execute'}"

    stdout

  _get_process: (...) =>
    exec_path = config.hg_path or 'hg'
    argv = { exec_path, ... }
    Process {
      cmd: argv,
      working_directory: @root,
      read_stdout: true,
      read_stderr: true,
    }

