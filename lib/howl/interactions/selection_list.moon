-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import app, bindings, interact, timer from howl
import ListWidget from howl.ui
import Matcher from howl.util

attach_list = (interactor) ->

class SelectionList
  run: (@finish, @opts) =>
    @command_line = app.window.command_line
    if not (@opts.matcher or @opts.items) or (@opts.matcher and @opts.items)
      error 'One of "matcher" or "items" required'

    @command_line.prompt = @opts.prompt
    @command_line.title = @opts.title

    matcher = @opts.matcher or Matcher @opts.items
    @list_widget = ListWidget matcher,
      on_selection_change: @\_selection_changed
      reverse: @opts.reverse
      never_shrink: true

    @list_widget.columns = @opts.columns

    @list_widget.max_height_request = math.floor app.window.allocated_height * 0.5

    @showing_list = false
    if not @opts.hide_until_tab
      @show_list!

    if @opts.text
      @command_line\write @opts.text
      @on_update @opts.text
    else
      if @opts.selection
        @list_widget\update ''
        @list_widget.selection = @opts.selection
        timer.asap -> @_selection_changed!
      else
        @on_update ''

  show_list: =>
    @command_line\add_widget 'completion_list', @list_widget
    @showing_list = true

  on_update: (text) =>
    @list_widget\update text
    @_selection_changed!

  _selection_changed: =>
    if @opts.on_selection_change
      @opts.on_selection_change @list_widget.selection, @command_line.text, @list_widget.items

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

    on_unhandled: (event, source, translations, self) ->
      return false if not @opts.keymap
      return ->
        if bindings.dispatch event, source, { @opts.keymap }, {
            selection: @list_widget.selection
            text: @command_line.text
          }
          @list_widget\update @command_line.text, true
          @_selection_changed!
        return false

interact.register
  name: 'select'
  description: 'Get selection made by user from a list of items'
  factory: SelectionList
