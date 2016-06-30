-- Copyright 2016 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import app, config, interact from howl
import ProcessBuffer from howl.ui
import Process from howl.io
import Matcher from howl.util
append = table.insert

install_gocode = ->
  howl.command.exec nil, 'go get -u -v github.com/nsf/gocode'

run_gocode = (context) ->
  gopath = howl.sys.env['GOPATH']
  if not gopath
    log.error 'GOPATH needs to be set to use gocode completions. See "go help gopath" for more information.'
    config.go_complete = false
    return nil
  exe = howl.io.File(gopath) / "bin"/ "gocode"
  unless exe.exists
    if interact.yes_or_no prompt: 'gocode not found for completions. Would you like to run "go get github.com/nsf/gocode" to install it?'
      install_gocode!
    else
      log.warn "gocode completions disabled"
      config.go_complete = false
      return nil

  cmd = { exe.path, '-f=csv', 'autocomplete', context.pos-1 }
  status, out, err, process = pcall Process.execute, cmd, stdin: context.buffer.text
  unless status and process.successful
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
        name = line\match '%w*,,(%w*),,[^,]*'
        append candidates, name
      candidates.authoritive = true
      table.sort candidates
    candidates

howl.completion.register name: 'go_completer', factory: GoCompleter
