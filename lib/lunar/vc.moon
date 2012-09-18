validate_vc = (name, vc) ->
  error '.files() missing from "' .. name .. '"', 3 if not vc.files
  error '.root missing from "' .. name .. '"', 3 if not vc.root

class VC
  available: {}

  register: (name, handler) ->
    error '`name` missing', 2 if not name
    error '`handler` missing', 2 if not handler
    error 'required `.find` not provided in handler', 2 if not handler.find
    VC.available[name] = handler

  unregister: (name) ->
    error '`name` missing', 2 if not name
    VC.available[name] = nil

  for_file: (file) ->
    for name, handler in pairs VC.available
      vc = handler.find file
      if vc
        validate_vc name, vc
        return vc

    nil

return VC
