-- Copyright 2019 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

{:app, :log} = howl
{:ListWidget, :List, :ActionBuffer, :highlight, :StyledText} = howl.ui
{:Matcher} = howl.util
{:Preview} = howl.interactions.util

append = table.insert

local ListItemView, ValueItemView

get_display_item = (item) ->
  return item unless item.display_row

  -- when explorer provides a display_row method, use that to get the row
  display_item = item\display_row!
  display_item = {display_item} if type(display_item) == 'string'

  -- store a reference to the original explorer object so it can be selected
  display_item.explorer = item
  return display_item

get_explorer_for_selection = (explorer, selection) ->
  -- given an item selected from the displayed list, and a parent explorer
  -- return the explorer for the selected item
  return unless selection
  if type(selection) == 'table' and selection.explorer
    return selection.explorer
  if explorer.get_item
    return explorer\get_item selection

level_kind = (item) ->
  -- a level can be either a container of items or an editable value
  if item.display_items
    return 'list'
  elseif item.get_value
    return 'value'
  else
    error "explorer is missing both display_items and get_value"

level_view = (item, explorer_view) ->
  switch level_kind item
    when 'list' then ListItemView item, explorer_view
    when 'value' then ValueItemView item, explorer_view

class ExplorerView
  new: (opts) =>
    @opts = moon.copy opts
    path = @opts.path or error 'path not provided'
    @base_prompt = @opts.prompt or ''
    @base_title = @opts.title
    if type @base_prompt.styles == 'string'
      @base_prompt = StyledText @base_prompt, 'keyword'
    @separator = @opts.separator or ''
    @editor = @opts.editor or app.editor

    -- levels is a stack of items, the current level is the top most item and is displayed
    -- each level has an associated item view (ListItemView or ValueItemView)
    @levels = {}
    for item in *path
      @_push_level item

  get_help: =>
    local_help = howl.ui.HelpContext!
    local_help\add_keys
      ctrl_r: 'Refresh view'

    level = @levels[#@levels]
    explorer_help = level.item.get_help and level.item\get_help!

    help = howl.ui.HelpContext!
    help\merge explorer_help
    help\merge local_help
    help

  init: (@command_line, opts={}) =>
    -- this view creates a list widget and a list, but delegates handing to the item view object
    @list = List nil,
      on_selection_change: (selection) ->
        level = @levels[#@levels]
        level.view\handle_selection_change selection
    @list_widget = ListWidget @list, never_shrink: true

    if opts.max_height
      @list_widget.max_height_request = opts.max_height

    -- when auto_trim, show trim markers at end of row text if too long
    if opts.max_width and @opts.auto_trim
      @list_widget.max_width_request = opts.max_width

    @command_line\add_widget 'explore_list', @list_widget

    @_refresh!

  _refresh: (text='') =>
    -- redraw the current level and set provided text
    level = @levels[#@levels]
    level.view\refresh text

  redraw_prompt: (prompt) =>
    full_prompt = @base_prompt
    full_prompt ..= prompt if prompt
    @command_line.prompt = full_prompt if full_prompt != @command_line.prompt

  redraw_text: (text) =>
    if text != @command_line.text
      -- this should trigger a call to @on_text_changed
      @command_line.text = text
    else
      -- call the changed hook anyway to trigger related redraws
      @on_text_changed text

  redraw_title: (title) =>
    if @base_title or title
      @command_line.title = (@base_title or '') .. (title or '')
    else
      @command_line.title = nil

  enter_level: (item, remaining_text='') =>
    -- add a new level to the levels stack and redraw
    @_push_level item
    ok, err = pcall -> @_refresh remaining_text
    unless ok
      log.error 'cannot render item: ' .. err
      error 'cannot render item', err

  jump_to_level: (path, remaining_text) =>
    -- replace the current levels stack with a new one
    @levels = {}
    for item in *path
      @_push_level item
    @_refresh remaining_text

  _push_level: (item) =>
    append @levels, {:item, view: level_view(item, self)}

  _exit_level: =>
    -- go back up one level
    if #@levels == 1
      @finish!
    else
      @levels[#@levels] = nil
      @_refresh!
      @levels[#@levels].view\handle_text ''

  preview: (item, text) =>
    -- display the preview for item in editor frame
    return unless @editor.preview
    unless item
      @_cancel_preview!
      return

    @previewer or= Preview!

    -- the item itself returns a preview table for the text
    preview = item.preview and item\preview text
    local buf
    if preview
      if preview.text
        buf = ActionBuffer!
        buf\append preview.text
      elseif preview.file
        buf = @previewer\get_buffer preview.file
      elseif preview.buffer
        buf = preview.buffer
      elseif preview.chunk
        buf = preview.chunk.buffer

    if buf
      buf.title = preview.title if preview.title
      @editor\preview buf
      if preview.chunk
        @_preview_highlight_chunk(preview.chunk)
        @_preview_popup(@editor, preview.chunk.start_pos, preview.popup) if preview.popup
    else
      @_cancel_preview!

  _preview_highlight_chunk: (chunk) =>
    buffer = chunk.buffer
    line = buffer.lines\at_pos chunk.start_pos
    @editor.line_at_center = line.nr
    highlight.remove_all 'search', buffer
    highlight.remove_all 'search_secondary', buffer
    highlight.apply 'search', buffer, chunk.start_pos, chunk.end_pos - chunk.start_pos + 1

  _preview_popup: (editor, pos, popup_text) =>
    popup = howl.ui.BufferPopup ActionBuffer!
    buf = popup.buffer
    buf\append popup_text
    with popup.view
      .cursor.line = 1
      .base_x = 0

    howl.timer.asap -> editor\show_popup popup, position: pos

  _cancel_preview: =>
    @editor\cancel_preview!

  on_text_changed: (text) =>
    level = @levels[#@levels]

    @command_line.notification\clear!
    @command_line.notification\hide!
    level.view\handle_text text

  finish: (result) =>
    @command_line\finish result
    return true

  on_close: =>
    @_cancel_preview!

  keymap:
    enter: =>
      level = @levels[#@levels]
      level.view\handle_enter @list.selection, @command_line.text

    binding_for:
      ['cursor-up']: =>
        @list\select_prev! if @list_widget.showing

      ['cursor-down']: =>
        @list\select_next! if @list_widget.showing

      ['cursor-page-up']: =>
        @list\prev_page! if @list_widget.showing

      ['cursor-page-down']: =>
        @list\next_page! if @list_widget.showing

    tab: => @list\select_next! if @list_widget.showing
    shift_tab: => @list\select_prev! if @list_widget.showing

    backspace: =>
      return false unless @command_line.text.is_empty
      @_exit_level!

    escape: => @finish!

    ctrl_r: => @_refresh!

    on_unhandled: (event, source, translations, self) ->
      level = @levels[#@levels]
      explorer = level.item
      return unless explorer and level.view.fire_action
      selection = @list.selection
      if explorer and explorer.actions
        actions = explorer\actions!
        for _, action_def in pairs actions
          for keystroke in *action_def.keystrokes
            if #[t for t in *translations when t == keystroke] > 0
              return ->
                status, err = pcall -> level.view\fire_action action_def.handler, selection
                if not status
                  error err

class ValueItemView
  new: (@item, @explorer_view) =>
    @options = @item.get_options and @item\get_options!

  refresh: (text) =>
    local current_value, title
    status, err = pcall ->
      current_value = @item\get_value!
      title = if @item.display_title then @item\display_title! else nil

    unless status
      error "Cannot load value: #{err}"

    if @options
      -- load options into the list
      matcher = Matcher @options
      -- determine option corresponding to current value
      for option in *@options
        if option.value == current_value
          @current_option = option

      @explorer_view.list.matcher = matcher
      @explorer_view.list_widget\show!
      -- options can be two columns: value, description
      @explorer_view.list.columns = {{style: 'string'}, {style: 'comment'}}
      @explorer_view\redraw_text text
    else
      @explorer_view.list_widget\hide!
      -- load the default value if not specified
      @explorer_view\redraw_text if text.is_empty then current_value else text

    @explorer_view\redraw_title title
    @explorer_view\redraw_prompt if @item.display_path then @item\display_path! else nil

  handle_text: (text) =>
    if @options
      -- filter the displayed options
      @explorer_view.list\update text
      if @current_option and text.is_empty
        -- select the current value whenever no text is given
        @explorer_view.list.selection = @current_option
    else
      -- save the new value (this doesn't apply the value, calling commit does')
      @item\set_value text
      @explorer_view\preview @item, text

  handle_selection_change: (selection) =>
    @explorer_view\preview @item, selection.value

  handle_enter: (selection) =>
    if @options
      -- set the selected option as the new value
      @item\set_value selection.value

    -- select current item
    @explorer_view\finish @item

class ListItemView
  new: (@item, @explorer_view) =>
    -- @item is the explorer object corresponding to this view

  refresh: (text) =>
    -- get the nested items and load the list
    local subitems, opts, title
    status, err = pcall ->
      subitems, opts = @item\display_items!
      title = if @item.display_title then @item\display_title! else nil

    unless status
      error "Cannot load items: #{err}"

    if @item.display_columns
      @explorer_view.list.columns = @item\display_columns!
    @list_initial_selection = @update_list_matcher subitems, opts
    @explorer_view\redraw_text text
    @explorer_view\redraw_title title
    @explorer_view\redraw_prompt if @item.display_path then @item\display_path! else nil

  handle_text: (text) =>
    if @item.parse  -- quick selection of an item without pressing enter
      status, response = pcall -> @item\parse text
      if not status
        @explorer_view.command_line.notification\error response
        @explorer_view.command_line.notification\show!
        return

      if response
        @_process_response response
        return

    @update_list text

  _process_response: (response) =>
    -- Some methods on the explorer object return responses that direct the explorer_view
    -- to behave a certain way. E.g. `parse` and actions.
    -- These responses are handled here.

    if response.jump_to
      -- jump_to should be an explorer object, it will be appended to the current path
      @explorer_view\enter_level response.jump_to, (response.text or '')
      return
    if response.jump_to_absolute
      -- jump_to_absolute should be a list of explorer objects, it will replace the current list
      @explorer_view\jump_to_level response.jump_to_absolute, (response.text or '')
      return

  update_list_matcher: (items, opts={}) =>
    display_items = {}
    local selection

    -- convert items to display items
    for item in *items
      local display_item
      display_item = get_display_item item

      append display_items, display_item
      if opts.selected_item == item
        selection = display_item

    matcher = Matcher display_items, preserve_order: opts.preserve_order

    if opts.find_hidden
      -- if hidden items may exist, we wrap a matcher in another that also searches hidden items
      inner_matcher = matcher
      matcher = (search) ->
        matches, match_opts = inner_matcher search
        return matches, match_opts if not search or search.is_blank
        item = opts.find_hidden search
        if item
          -- a hidden item was found, copy matches and append hidden item
          matches = moon.copy matches
          append matches, get_display_item item
        matches, match_opts

    @explorer_view.list.matcher = matcher
    return selection

  update_list: (text) =>
    @explorer_view.list\update text
    @explorer_view.list_widget\show!
    if @list_initial_selection
      @explorer_view.list.selection = @list_initial_selection
      @list_initial_selection = nil

  handle_selection_change: (selection) =>
    item = get_explorer_for_selection @item, selection
    @explorer_view\preview item

  handle_enter: (selection) =>
    item = get_explorer_for_selection @item, selection
    item or= selection

    if item.display_items or item.get_value
      @explorer_view\enter_level item
    else
      @explorer_view\finish item

  fire_action: (action_handler, selection) =>
    selected_item = get_explorer_for_selection @item, selection
    selected_item or= selection

    status, response = pcall -> action_handler @item, selected_item
    unless status
      error "Could not fire action: #{response}"

    if response
      @_process_response response
    else
      -- we refresh the list view so any changes affected by the action are displayed
      -- (e.g. if a buffer is closed, it should immediately disappear from the list)
      @refresh @explorer_view.command_line.text

return ExplorerView
