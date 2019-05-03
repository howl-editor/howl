--- Copyright 2012-2017 The Howl Developers
--- License: MIT (see LICENSE.md at the top-level directory of the distribution)

howl.interact.register
  name: 'get_variable_assignment'
  description: 'Get config variable and value selected by user'
  handler: (opts={}) ->
    howl.interact.explore
      prompt: opts.prompt
      path: {howl.explorers.ConfigExplorer howl.app.editor.buffer}
      text: opts.text
      help: opts.help
      transform_result: (config_value) ->
        {
          :config_value
          text: config_value\display_path! .. config_value\new_value_str!
        }
