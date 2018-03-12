import Process from howl.io
import config, app, activities from howl

insp = (buffer) ->
  if app.editor.buffer.modified -- the buffer has to be saved
    return nil
  if config.go_tool_vet == true
    success, ret = pcall Process.open_pipe, {'go', 'tool', 'vet', app.editor.buffer.file}
    if success
      _, err = activities.run_process {title: 'Running go tool vet'}, ret
      t = {}
      for l,m in string.gmatch(err,'.go:(%d+):%s*([^\n]+)')
        table.insert(t,{
          line: tonumber(l)
          message: m
          type: 'error'
        })
      -- return inspection table
      return t
    else
      log.error "go tool vet error: #{ret}"
      return nil

return insp
