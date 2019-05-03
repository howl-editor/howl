-- Copyright 2019 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

{:ListWidget, :List} = howl.ui
{:Matcher} = howl.util

class ConsoleView
  new: (@console) =>

  init: (@command_line, opts={}) =>
    @list = List nil,
      never_shrink: true,
      on_selection_change: (selection) ->
    @list_widget = ListWidget @list
    if opts.max_height
      @list_widget.max_height_request = opts.max_height
    @command_line\add_widget 'completer', @list_widget
    @list_widget\hide!

  on_text_changed: =>
    if @history_showing
      -- filter history
      @list\update @command_line.text
    else
      -- refresh command list
      @_refresh!

  keymap:
    enter: =>
      if @history_showing
        -- we only set the command line text
        @history_showing = false
        @_hide_list!
        item = @list.selection
        if item.text
          @command_line.text = item.text
        elseif type(item) == 'table'
          @command_line.text = tostring item[1]
        else
          @command_line.text = tostring item
        return

      local status, response
      if @list_widget.showing
        status, response = pcall -> @console\select @command_line.text, @list.selection, @completion_opts
      else
        status, response = pcall -> @console\run @command_line.text

      if status
        @_hide_list!
        return if @_handle_response response
      else
        @_handle_error response

    escape: =>
      if @history_showing
        -- just close list and cancel history_showing
        @_hide_list!
        @history_showing = false
        return

      if @list_widget.showing
        @_hide_list!
      else
        @command_line\finish!

    backspace: =>
      return false unless @command_line.text.is_empty and @console.back

      status, response = pcall -> @console\back!
      if status
        if response
          return if @_handle_response response
        else
          @_refresh!
      else
        @_handle_error response

    tab: =>
      if not @list_widget.showing and @completion_opts
        @_show_completions!

    binding_for:
      ['cursor-up']: =>
        if @list_widget.showing
          @list\select_prev!
        else
          @_show_history!

      ['cursor-down']: =>
        @list\select_next! if @list_widget.showing

      ['cursor-page-up']: =>
        @list\prev_page! if @list_widget.showing

      ['cursor-page-down']: =>
        @list\next_page! if @list_widget.showing

  _refresh: =>
    with @command_line.notification
      \clear!
      \hide!

    text = @command_line.text

    -- update title and prompt
    if @console.display_title
      @command_line.title = @console\display_title!
    else
      @command_line.title = nil

    @command_line.prompt = @console\display_prompt!

    -- handle parsing, if available
    if @console.parse
      status, response = pcall -> @console\parse text
      if status
        if response
          if @_handle_response response
            return
      else
        @_handle_error response

    -- show completions, if available
    @completion_opts = @console.complete and @console\complete text
    if @completion_opts
      if @list_widget.showing or @completion_opts.auto_show
        @_show_completions @completion_opts
      else
        @_hide_list!
    else
      @_hide_list!

  _show_completions: =>
    @list_widget\show!
    @list.matcher = Matcher @completion_opts.completions
    @list.reverse = false
    if @completion_opts.columns
      @list.columns = @completion_opts.columns
    @list\update @completion_opts.match_text

  _show_history: =>
    if @console.get_history
      history_items = @console\get_history!
      return unless history_items

      @list_widget\show!
      @list.matcher = Matcher history_items, preserve_order: true
      @list.reverse = true
      @list\update ''
      @history_showing = true

  _hide_list: => @list_widget\hide!

  _handle_response: (r) =>
    if r.text
      @command_line.text = r.text
      @_refresh!
    if r.error
      @_handle_error r.error
    if r.result
      @command_line\finish r.result
      return true
    if r.cancel
      @command_line\finish!
      return true

  _handle_error: (msg) =>
    log.error msg
    @command_line.notification\error msg
    @command_line.notification\show!


