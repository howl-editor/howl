-- Copyright 2016 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

util = bundle_load 'util'

(buffer) ->
  path = buffer.file or buffer.directory
  ruby_cmd = util.ruby_command_for path

  {
    cmd: "#{ruby_cmd} -w -c"

    is_available: -> ruby_cmd != nil

    post_parse: (inspections) ->
      for i in *inspections
        unless i.search
          search = i.message\match 'variable %- (.+)$'
          search or= i.message\match "`([^']+)'"
          i.search = search
  }
