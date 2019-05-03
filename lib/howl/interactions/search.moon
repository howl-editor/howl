-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import app, interact from howl

class SearchInteraction
  new: (@operation, @type, opts={}) =>
    @searcher = app.editor.searcher
    @opts = moon.copy opts

    @keymap = moon.copy @keymap
    for keystroke in *opts.backward_keys
      @keymap[keystroke] = -> @searcher\previous!
    for keystroke in *opts.forward_keys
      @keymap[keystroke] = -> @searcher\next!

  init: (@command_line) =>
    @command_line.prompt = @opts.prompt
    @command_line.title = @opts.title
    @command_line.notification\show!

  on_text_changed: (text) =>
    @searcher[@operation] @searcher, text, @type

  help: {
    {
      key: 'up'
      action: 'Select previous match'
    }
    {
      key: 'down'
      action: 'Select next match'
    }
  }

  keymap:
    up: => @searcher\previous!
    down: => @searcher\next!
    enter: => @command_line\finish @command_line.text
    escape: =>
      @searcher\cancel!
      @command_line\finish!

interact.register
  name: 'search'
  description: 'Generic search interaction'
  handler: (operation, type, opts={}) ->
    error 'operation and type required' unless operation and type
    search_interaction = SearchInteraction operation, type, opts
    app.window.command_panel\run search_interaction, text: opts.text


interact.register
  name: 'forward_search'
  description: ''
  handler: (opts) ->
    interact.search 'forward_to', 'plain'
      prompt: opts.prompt
      text: opts.text
      title: opts.title or 'Forward Search'
      forward_keys: howl.bindings.keystrokes_for('buffer-search-forward', 'editor')
      backward_keys: howl.bindings.keystrokes_for('buffer-search-backward', 'editor')

interact.register
  name: 'backward_search'
  description: ''
  handler: (opts) ->
    interact.search 'backward_to', 'plain'
      prompt: opts.prompt
      text: opts.text
      title: opts.title or 'Backward Search'
      forward_keys: howl.bindings.keystrokes_for('buffer-search-forward', 'editor')
      backward_keys: howl.bindings.keystrokes_for('buffer-search-backward', 'editor')

interact.register
  name: 'forward_search_word'
  description: ''
  handler: (opts) ->
    interact.search 'forward_to', 'word',
      prompt: opts.prompt
      text: opts.text
      title: opts.title or 'Forward Word Search'
      forward_keys: howl.bindings.keystrokes_for('buffer-search-word-forward', 'editor')
      backward_keys: howl.bindings.keystrokes_for('buffer-search-word-backward', 'editor')

interact.register
  name: 'backward_search_word'
  description: ''
  handler: (opts) ->
    interact.search 'backward_to', 'word',
      prompt: opts.prompt
      text: opts.text
      title: opts.title or 'Backward Word Search',
      forward_keys: howl.bindings.keystrokes_for('buffer-search-word-forward', 'editor')
      backward_keys: howl.bindings.keystrokes_for('buffer-search-word-backward', 'editor')
