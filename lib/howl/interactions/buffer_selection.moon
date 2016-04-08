-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import app, config, interact, Project from howl
import File from howl.io
import icon, markup from howl.ui
import Matcher from howl.util

append = table.insert

config.define
  name: 'buffer_icons'
  description: 'Whether buffer icons are displayed'
  scope: 'global'
  type_of: 'boolean'
  default: true

icon.define_default 'buffer', 'font-awesome-square'
icon.define_default 'buffer-modified', 'font-awesome-pencil-square-o'
icon.define_default 'buffer-modified-on-disk', 'font-awesome-clone'
icon.define_default 'process-success', 'font-awesome-check-circle'
icon.define_default 'process-running', 'font-awesome-play-circle'
icon.define_default 'process-failure', 'font-awesome-exclamation-circle'

buffer_dir = (buffer) ->
  if buffer.file
    return buffer.file.parent.short_path
  elseif buffer.directory
    return buffer.directory.short_path
  return '(none)'

buffer_status_text = (buffer) ->
  stat = if buffer.modified then '*' else ''
  stat ..= '[modified on disk]' if buffer.modified_on_disk
  stat

buffer_status_icon = (buffer) ->
  local name
  if typeof(buffer) == 'ProcessBuffer'
    if buffer.process.exited
      name = buffer.process.successful and 'process-success' or 'process-failure'
    else
      name = 'process-running'
  else
    if buffer.modified_on_disk
      name = 'buffer-modified-on-disk'
    elseif buffer.modified
      name = 'buffer-modified'
    else
      name = 'buffer'

  return icon.get(name, 'operator')

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

  title = (buffer) -> enhanced_titles[buffer] or buffer.title
  if config.buffer_icons
    return [{buffer_status_icon(buffer), title(buffer), buffer_dir(buffer), :buffer} for buffer in *app.buffers]
  else
    return [{title(buffer), buffer_status_text(buffer), buffer_dir(buffer), :buffer} for buffer in *app.buffers]

buffer_matcher = (text) ->
  matcher = Matcher get_buffer_list!
  return matcher(text)

interact.register
  name: 'select_buffer'
  description: 'Selection list for buffers'
  handler: (opts={}) ->
    opts = moon.copy opts
    local columns
    if config.buffer_icons
      columns = {
        {},
        {style: 'string'}
        {style: 'comment'}
      }
    else
      columns = {
        {style: 'string'}
        {style: 'operator'}
        {style: 'comment'}
      }
    current_selection = nil
    with opts
      .title or= 'Buffers'
      .matcher = buffer_matcher
      .columns = columns
      .on_change = (selection, text, items) ->
        current_selection = selection

    command_line = howl.app.window.command_line
    command_line.keymap = {
      binding_for:
        ['buffer-close']: =>
          if current_selection and current_selection.buffer
            app\close_buffer current_selection.buffer
            command_line\refresh!
    }

    result = interact.select_location opts
    if result
      return result.selection.buffer
