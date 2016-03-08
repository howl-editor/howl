-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import app, interact, Project from howl
import File from howl.io
import Matcher from howl.util

append = table.insert

buffer_dir = (buffer) ->
  if buffer.file
    return buffer.file.parent.short_path
  elseif buffer.directory
    return buffer.directory.short_path
  return '(none)'

buffer_status = (buffer) ->
  stat = if buffer.modified then '*' else ''
  stat ..= '[modified on disk]' if buffer.modified_on_disk
  stat


make_title = (buffer, opts={}) ->
  file = buffer.file
  title = file.basename
  if opts.parents
    parent = file.parent
    for i=1,opts.parents
      if parent
        title = "#{parent.basename}#{File.separator}#{title}"
        parent = parent.parent
      else
        break

  if opts.project
    project = Project.for_file file
    if project
      title = "#{title} [#{project.root.basename}]"

  return title

has_duplicates = (list) ->
  set = {}
  for item in *list
    return true if set[item]
    set[item] = true
  return false

get_buffer_list = ->
  basenames = {}
  enhanced_titles = {}

  for buf in *app.buffers
    continue unless buf.file and buf.file.basename == buf.title
    basenames[buf.file.basename] or= {}
    append basenames[buf.file.basename], buf

  for basename, buffers in pairs(basenames)
    continue if #buffers == 1

    options_list = {
      { project: true }
      { project: false, parents: 1 }
      { project: true, parents: 1 }
      { project: false, parents: 2 }
      { project: true, parents: 2 }
    }

    titles = nil
    for options in *options_list
      titles = [make_title buffer, options for buffer in *buffers]
      break if not has_duplicates titles

    for i=1,#buffers
      enhanced_titles[buffers[i]] = titles[i]

  return [{enhanced_titles[buffer] or buffer.title, buffer_status(buffer), buffer_dir(buffer), :buffer} for buffer in *app.buffers]

buffer_matcher = (text) ->
  matcher = Matcher get_buffer_list!
  return matcher(text)

interact.register
  name: 'select_buffer'
  description: 'Selection list for buffers'
  handler: (opts={}) ->
    opts = moon.copy opts
    with opts
      .title or= 'Buffers'
      .matcher = buffer_matcher
      .columns = {
        {style: 'string'}
        {style: 'operator'}
        {style: 'comment'}
      }
      .keymap = {
        binding_for:
          ['close']: (current) ->
            if current.selection
              app\close_buffer current.selection.buffer
      }

    result = interact.select_location opts
    if result
      return result.selection.buffer
