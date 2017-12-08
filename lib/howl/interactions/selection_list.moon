-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import app, interact, timer from howl
import ListWidget from howl.ui
import Matcher from howl.util

class SelectionList
  run: (@finish, @opts) =>
    @command_line = app.window.command_line
    if not (@opts.matcher or @opts.items) or (@opts.matcher and @opts.items)
      error 'One of "matcher" or "items" required'

    @command_line.prompt = @opts.prompt
    @command_line.title = @opts.title

    matcher = @opts.matcher or Matcher @opts.items
    @list_widget = ListWidget matcher,
      on_selection_change: @\_handle_change
      reverse: @opts.reverse
      never_shrink: true
      explain: @opts.explain

    @list_widget.columns = @opts.columns

    @list_widget.max_height_request = math.floor app.window.allocated_height * 0.5

    @showing_list = false
    if not @opts.hide_until_tab
      @show_list!

    @quick_selections = {}
    if @opts.items
      for item in *@opts.items
        if item.quick_select
          if type(item.quick_select) == 'table'
            for quick_select in *item.quick_select
              @quick_selections[quick_select] = item
          else
            @quick_selections[item.quick_select] = item

    if @opts.text
      @command_line\write @opts.text
      @on_update @opts.text
    else
      spillover = @command_line\pop_spillover!
      @command_line\write spillover
      if @opts.selection
        @list_widget\update spillover
        @list_widget.selection = @opts.selection
        timer.asap -> @_handle_change!
      else
        @on_update spillover

  refresh: => @list_widget\update @command_line.text, true

  show_list: =>
    @command_line\add_widget 'completion_list', @list_widget
    @showing_list = true

  on_update: (text) =>
    if @quick_selections[text]
      self.finish
        selection: @quick_selections[text]
        :text
        quick: true
      return

    @_change_triggered = false
    @list_widget\update text
    @_handle_change! unless @_change_triggered

  _handle_change: =>
    @_change_triggered = true
    if @opts.on_change
      @opts.on_change @list_widget.selection, @command_line.text, @list_widget.items

  submit: =>
    if @list_widget.selection
      self.finish
        selection: @list_widget.selection
        text: @command_line.text
    elseif @opts.allow_new_value
      self.finish text: @command_line.text
    else
      log.error 'Invalid selection'

  keymap:
    enter: => @submit!
    escape: => self.finish!
    tab: =>
      if not @showing_list
        @show_list!

    space: =>
      return false unless @opts.submit_on_space

      if @command_line.text.is_empty
        @show_list!
      else
        @submit!

  handle_back: =>
    if @opts.cancel_on_back
      self.finish back: true

interact.register
  name: 'select'
  description: 'Get selection made by user from a list of items'
  factory: SelectionList
