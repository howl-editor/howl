-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import app, interact from howl

interact.register
  name: 'yes_or_no'
  description: "Get choice made by user to a yes/no question"
  handler: (opts={}) ->
    opts = moon.copy opts
    with opts
      .items = {'Yes', 'No'}
      .selection or= 'No'

    app.window.command_line\clear_all!

    selection = interact.select opts
    return selection and selection.selection == 'Yes'
