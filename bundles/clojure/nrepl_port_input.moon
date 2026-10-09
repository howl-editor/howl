-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import app, Project, interact from howl

-- the port in the .nrepl-port file of the current buffer's project, if any
project_port = ->
  file = app.editor and app.editor.buffer.file
  project = file and Project.for_file file
  return nil unless project
  port_file = project.root / '.nrepl-port'
  port_file.exists and port_file.contents.stripped or nil

interact.register
  name: 'read_nrepl_port'
  description: 'A port (number) for an NRepl instance'
  handler: (opts={}) ->
    text = opts.text
    text = project_port! if not text or text.is_blank
    text = interact.read_text
      prompt: opts.prompt
      title: 'NRepl port'
      :text
      help: opts.help

    return unless text
    port = tonumber text
    log.error "Not a port number: '#{text}'" unless port
    port
