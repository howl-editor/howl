-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import interact from howl
import BufferExplorer from howl.explorers


interact.register
  name: 'select_buffer'
  description: ''
  handler: (opts={}) ->
    interact.explore
      prompt: opts.prompt
      text: opts.text
      help: opts.help
      path: {BufferExplorer -> howl.app.buffers}
      editor: opts.editor
      transform_result: (item) -> item.buffer
