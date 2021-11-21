-- Copyright 2019 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

{:app, :config, :Project} = howl
{:File} = howl.io
{:buffer_status_icon} = howl.ui.buffer_icon

append = table.insert

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

make_title = (buffer, opts={}) ->
  file = buffer.file
  title = file.basename
  if opts.parents
    parent = file.parent
    for _ = 1, opts.parents
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

class BufferItem
  new: (@buffer, @title) =>
  display_row: =>
    if config.buffer_icons
      {buffer_status_icon(@buffer), @title, buffer_dir(@buffer)}
    else
      {@title, buffer_status_text(@buffer), buffer_dir(@buffer)}
  preview: => buffer: @buffer

class BufferExplorer
  new: (get_buffers, opts={}) =>
    unless get_buffers
      error 'BufferExplorer requires get_buffers function'
    @get_buffers = get_buffers
    @opts = moon.copy opts
    @_refresh_buffers!

  get_help: =>
    help = howl.ui.HelpContext!
    help\add_keys
      ['buffer-close']: "Close currently selected buffer"
    help

  actions: =>
    close:
      keystrokes: howl.bindings.keystrokes_for 'buffer-close', 'editor'
      handler: (selected_item) =>
        -- Close the selected buffer
        -- We save the next or previous position in @jump_to_buffer which is
        -- used to preserve the position of the selection in the list of buffers.
        -- Otherwise a redraw would just select the first item.
        for idx, buf in ipairs @buffers
          if selected_item.buffer == buf
            @jump_to_buffer = @buffers[idx + 1] or @buffers[idx]
            break
        app\close_buffer selected_item.buffer
        @_refresh_buffers!

  display_title: => @opts.title or 'Buffers list'

  _refresh_buffers: =>
    -- construct the buffers list and enhanced_titles
    @buffers = self.get_buffers!
    buffers = @buffers
    basenames = {}
    @enhanced_titles = {}

    for buf in *buffers
      continue unless buf.file and buf.file.basename == buf.title
      basenames[buf.file.basename] or= {}
      append basenames[buf.file.basename], buf

    for _, buffer_group in pairs(basenames)
      continue if #buffer_group == 1

      options_list = {
        { project: true }
        { project: false, parents: 1 }
        { project: true, parents: 1 }
        { project: false, parents: 2 }
        { project: true, parents: 2 }
      }

      titles = nil
      for options in *options_list
        titles = [make_title buffer, options for buffer in *buffer_group]
        break if not has_duplicates titles

      for i=1,#buffer_group
        @enhanced_titles[buffer_group[i]] = titles[i]

  display_items: =>
    items = [BufferItem(buffer, @title_for(buffer)) for buffer in *@buffers]
    jump_to_item = [item for item in *items when item.buffer == @jump_to_buffer]
    @jump_to_buffer = nil
    return items, selected_item: jump_to_item[1]

  display_columns: =>
    name_width = math.min 100, math.max(table.unpack [@title_for(buffer).ulen for buffer in *@buffers])
    if config.buffer_icons
      {{}, {style: 'string', min_width: name_width}, {style: 'comment'}}
    else
      {{style: 'string', min_width: name_width}, {style: 'operator'}, {style: 'comment'}}

  title_for: (buffer) => @enhanced_titles[buffer] or buffer.title
