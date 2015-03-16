-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import app, Project, interact from howl

interact.register
  name: 'read_nrepl_port'
  description: 'A port (number) for an NRepl instance'
  handler: ->
    items = {}
    file = app.editor.buffer.file
    if file
      project = Project.for_file file
      if project
        port_file = project.root / '.nrepl-port'
        if port_file.exists
          items = { { port_file.contents, tostring(project.root) } }

    selected = interact.select
      :items
      allow_new_value: true
      columns: {
            { style: 'string' },
            { style: 'comment' },
      }

    if selected
      if selected.selection
        return tonumber selected.selection[1]
      elseif selected.text and not selected.text.is_empty
        return tonumber selected.text
