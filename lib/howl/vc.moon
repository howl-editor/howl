{:activities} = howl
{:File} = howl.io
TYPE_REGULAR = File.TYPE_REGULAR

validate_vc = (name, vc) ->
  error '.paths() missing from "' .. name .. '"', 3 if not vc.paths
  error '.root missing from "' .. name .. '"', 3 if not vc.root
  error '.name missing from "' .. name .. '"', 3 if not vc.name

files = (vc) ->
  paths = vc\paths!
  activities.run {
    title: "Loading files from '#{vc.root}'",
    status: -> "Loading files from #{#paths} #{vc.name} entries..",
  }, ->
    groot = vc.root.gfile
    return for i = 1, #paths
      activities.yield! if i % 1000 == 0
      path = paths[i]
      gfile = groot\get_child(path)
      File gfile, nil, type: TYPE_REGULAR

decorate_vc = (vc) ->
  if not vc.files
    vc = setmetatable({:files}, __index: vc)

  vc

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
        return decorate_vc(vc)

    nil

return VC
