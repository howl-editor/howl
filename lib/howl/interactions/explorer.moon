-- Copyright 2018 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

howl.interact.register
  name: 'explore'
  description: 'Generic explorer interaction'
  handler: (opts={}) ->
    error 'path required' unless opts.path
    explorer_view = howl.ui.ExplorerView path: opts.path, prompt: opts.prompt, title: opts.title, auto_trim: opts.auto_trim, editor: opts.editor
    item = howl.app.window.command_panel\run explorer_view, text: opts.text, help: opts.help
    return unless item != nil
    return item unless opts.transform_result
    return opts.transform_result item
