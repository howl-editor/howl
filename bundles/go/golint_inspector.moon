import Process from howl.io
import config, app, activities from howl

insp = (buffer) ->
  if app.editor.buffer.modified -- the buffer has to be saved
    return nil
  if config.go_lint == true
    success, ret = pcall Process.open_pipe, {'golint', app.editor.buffer.file}
    if success
      out, err = activities.run_process {title: 'Running golint'}, ret
      if ret.successful and err.is_blank
        t = {}
        -- parse the output (out)

        for l,m in string.gmatch(out,'.go:(%d+):%d+:%s*([^\n]+)')
          table.insert(t,{
            line: tonumber(l)
            message: m
            type: 'warning'
          })

        -- return inspection table
        return t
      return nil
    else
      log.error "golint error: #{ret}"
      return nil

return insp
