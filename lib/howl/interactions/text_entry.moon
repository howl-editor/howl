-- Copyright 2012-2019 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import interact from howl

class TextReader
  new: (opts={}) =>
    @opts = moon.copy opts

  init: (@command_line, opts = {}) =>
    @command_line.prompt = @opts.prompt
    @command_line.title = @opts.title

  keymap:
    enter: =>
      @command_line\finish @command_line.text

    escape: => @command_line\finish!

interact.register
  name: 'read_text'
  description: 'Read free form text entered by user'
  handler: (opts={}) ->
    howl.app.window.command_panel\run TextReader(opts), text: opts.text, help: opts.help
