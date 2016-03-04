-- Copyright 2016 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import app, config, interact from howl
import ProcessBuffer from howl.ui
import Process from howl.io
import Matcher from howl.util
append = table.insert

install_gocode = ->
  p = Process {
    cmd: { 'go', 'get', '-u', '-v', 'github.com/nsf/gocode' },
    read_stdout: true,
    read_stderr: true,
  }

  buffer = ProcessBuffer p
  editor = app\add_buffer buffer
  editor.cursor\eof!
  buffer\pump!
  
run_gocode = (context) ->
  cmd = { 'gocode', '-f=csv', 'autocomplete', context.pos-1 }
  status, out, err, process = pcall Process.execute, cmd, stdin: context.buffer.text
  unless status
    error out unless out\match 'No such file'
    if interact.yes_or_no prompt: 'gocode not found for completions. Would you like to run "go get github.com/nsf/gocode" to install it?'
      install_gocode!
    else
      log.warn "gocode completions disabled"
      config.go_complete = false
    return nil
  
  unless process.successful
    log.error "gocode failed to execute: #{err}"
    return nil
    
  out
  
class GoCompleter
  complete: (context) =>
    return {} unless config.go_complete

    out = run_gocode context
    candidates = {}
    if out
      for line in out\gmatch '[^\n]+'
        sym, name, type = line\match '(%w*),,(%w*),,([^,]*)'
        append candidates, name
      candidates.authoritive = true
    candidates

howl.completion.register name: 'go_completer', factory: GoCompleter
