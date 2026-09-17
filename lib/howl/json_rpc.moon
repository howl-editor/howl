{
  request: (method, params, id = nil) ->
    {
      jsonrpc: "2.0",
      method: method,
      :params,
      :id
    }
}


