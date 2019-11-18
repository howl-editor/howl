-- Copyright 2012-2018 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

{:interact} = howl
{:Preview} = howl.interactions.util

local LocationExplorer, LocationItem

interact.register
  name: 'select_location'
  description: 'Selection list for locations which specify positions or chunks within files'
  handler: (opts={}) ->
    interact.explore
      title: opts.title
      prompt: opts.prompt
      text: opts.text
      path: {LocationExplorer opts.items, opts.selection, opts.columns, opts.preserve_order}
      transform_result: (location_item) -> location_item.location
      help: opts.help

class LocationExplorer
  new: (@locations, @selected_location, @columns, @preserve_order) =>
    error 'locations required' unless @locations
    @previewer = Preview!

  display_path: => ''

  display_columns: => @columns

  display_items: =>
    items = [LocationItem(location, @previewer) for location in *@locations]
    local selected_item
    if @selected_location
      selected_item = ([item for item in *items when item.location == @selected_location])[1]
    return items, :selected_item, preserve_order: @preserve_order

class LocationItem
  new: (@location, @previewer) =>
    unless @location.buffer or @location.file or @location.chunk
      error 'location.buffer or location.file or location.chunk required'

  get_chunk: =>
    -- return a chunk that corresponds to this location
    return @location.chunk if @location.chunk

    local buffer
    preview_msg = ''
    line_nr = @location.line_nr or 1

    if @location.buffer
      buffer = @location.buffer
    elseif @location.file
      -- if we have a file we get the chunk from the preview buffer
      buffer = self.previewer\get_buffer @location.file, line_nr or 1
      preview_msg = ' in preview'

    if @location.pos
      pos = @location.pos
      if pos <= buffer.length
        return buffer\chunk pos, pos
      else
        @warning = "Position #{pos} not loaded#{preview_msg}"
    else
      line = buffer.lines[line_nr]
      if line
        -- either return the whole line or a segment (when start_column is provided)
        if @location.start_column or @location.byte_start_column
          span = {
            start_column: @location.start_column
            end_column: @location.end_column or @location.start_column
            byte_start_column: @location.byte_start_column
            byte_end_column: @location.byte_end_column or @location.byte_start_column
          }
          return buffer\chunk_for_span span, line_nr
        else
          return line.chunk
      else
        @warning = "Line #{line_nr} not loaded#{preview_msg}"

    -- if we weren't able to load a chunk, return the last line
    line = buffer.lines[#buffer.lines]
    return line.chunk

  display_row: => @location

  preview: =>
    unless @chunk
      @chunk = @get_chunk!
    if @warning
      log.warn @warning
    if @chunk
      return chunk: @chunk, popup: @location.popup
    else
      return text: 'Preview not available'
