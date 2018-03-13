(buffer) ->
  {
    cmd: 'go tool vet <file>'
    parse: (o) ->
      [{line: tonumber(l), message: m, type: 'error'} for l,m in string.gmatch(o,'.go:(%d+):%s*([^\n]+)')]
  }
