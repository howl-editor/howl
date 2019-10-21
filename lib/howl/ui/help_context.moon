-- Copyright 2019 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import bindings from howl
import ActionBuffer, markup, style from howl.ui

append = table.insert

style.define_default 'keystroke', 'special'


local HelpContext

class HelpContext
  new: =>
    @sections = {}  -- list of {heading:, text:} tables
    @keys = {}  -- list of {key:, text:} tables

  merge: (help) =>
    -- merge another help context into this one
    return unless help
    for s in *help.sections
      append @sections, s
    for k in *help.keys
      append @keys, k

  add_section: (section) =>
    -- section should be table {heading:, text:}
    append @sections, {heading: section.heading, text: if section.text then markup.howl section.text}

  add_keys: (key_defs) =>
    if #key_defs > 0
      -- assume list of tables
      for def in *key_defs
        @add_keys def
      return

    for keyname, text in pairs key_defs
      text = markup.howl text
      -- keyname could be a keystroke or a command name
      keystrokes = bindings.keystrokes_for(keyname, 'editor')
      if #keystrokes > 0
        -- keyname is a command name, insert mapped keystrokes
        for key in *keystrokes
          append @keys, {:key, :text}
      else
        -- assume keyname is a keystroke name
        append @keys, {key:keyname, :text}

  get_buffer: =>
    -- return a styled buffer containing help info
    buffer = ActionBuffer!
    buffer.text = ''

    for i, section in ipairs @sections
      if section.heading
        buffer\append markup.howl "<h1>#{section.heading}</>\n\n"
      if section.text
        buffer\append section.text
        buffer\append '\n'
      if i < #@sections or #@keys > 0 -- newlines between sections only
        buffer\append "\n"

    if #@keys > 0
      buffer\append markup.howl "<h1>Keys</>\n"
      keys = {}
      for keydef in *@keys
        key = keydef.key
        if key
          append keys, {markup.howl("<keystroke>#{key}</>"), keydef.text}

      buffer\append howl.ui.StyledText.for_table keys

    buffer

