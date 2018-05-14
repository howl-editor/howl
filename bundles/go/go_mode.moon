-- Copyright 2016-2018 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)
{:activities, :Buffer, :config, :mode, :sys} = howl
{:Process} = howl.io

bundle_load 'go_completer'
{:fmt} = bundle_load 'go_fmt'

{
  auto_pairs: {
    '(': ')'
    '[': ']'
    '{': '}'
    '"': '"'
    "'": "'"
    "`": "`"
  }

  comment_syntax: '//'

  completers: { 'in_buffer', 'go_completer' }

  default_config:
    use_tabs: true
    tab_width: 4
    indent: 4
    inspectors_on_save: { 'golint', 'gotoolvet' }

  lexer: bundle_load('go_lexer')

  structure: (editor) =>
    [l for l in *editor.buffer.lines when l\match('^%s*func%s') or l\match('^%s*struct%s') or l\match('^%s*type%s')]

  before_save: (buffer) =>
    if config.go_fmt_on_save
      fmt buffer

  show_doc: (editor) =>
    cmd_path = config.gogetdoc_path
    unless sys.find_executable cmd_path
      log.warning "Command '#{cmd_path}' not found, please install for docs"
      return

    buffer = editor.buffer
    cmd_str = string.format "#{cmd_path} -pos %s:#%d -modified -linelength 999",
      buffer.file,
      buffer\byte_offset(editor.cursor.pos) - 2
    success, pco = pcall Process.open_pipe, cmd_str, {
      stdin: string.format("%s\n%d\n%s", buffer.file, buffer.size, buffer.text)
    }
    unless success
      log.error "Failed looking up docs: #{pco}"
      return

    stdout, _ = activities.run_process {title: 'running gogetdoc'}, pco
    unless stdout.is_empty
      buf = Buffer mode.by_name 'default'
      buf.text = stdout
      return buf
}
