(buffer) ->
  {
    cmd: 'golint <file>'
    parse: (o) ->
      [{line: tonumber(l), message: m, type: 'warning'} for l,m in string.gmatch(o,'.go:(%d+):%d+:%s*([^\n]+)')]
  }
