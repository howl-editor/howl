import app, Project from howl

class NReplPortInput
  should_complete: -> true
  close_on_cancel: -> true

  new: =>
    if editor
      file = editor.buffer.file
      if file
        project = Project.for_file file
        if project
          port_file = project.root / '.nrepl-port'
          @ports = { { port_file.contents, tostring(project.root) } } if port_file.exists

  complete: (text) =>
    completion_options = title: 'NRepl instances', list: column_styles: { 'string', 'comment' }
    return @ports, completion_options

  value_for: (port) =>
    tonumber port

howl.inputs.register 'nrepl_port', NReplPortInput
return NReplPortInput
