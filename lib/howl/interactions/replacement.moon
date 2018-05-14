-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import TaskRunner from howl.util
import app, command, interact from howl
import highlight, markup, NotificationWidget from howl.ui

append = table.insert

highlight.define_default 'replace_strikeout', {
  type: highlight.SANDWICH,
  color: '#f0f0f0'
}

parse_replacement = (text, marker) ->
  target, replacement = text\match("([^#{marker}]+)#{marker}(.*)")
  if target
    return target, replacement
  return text

default_find = (buffer, target, init) ->
  init = buffer\byte_offset init
  text = buffer.text
  ->
    start_pos, end_pos  = text\find target, init, true
    if not start_pos
      return
    init = end_pos + 1
    return { start_pos: buffer\char_offset(start_pos), end_pos: buffer\char_offset(end_pos) }


class Replacement
  run: (@finish, opts={}) =>
    @command_line = app.window.command_line
    with opts.editor
      @text = .buffer.text
      @line_at_top = .line_at_top
      @orig_cursor_pos = .cursor.pos

    -- @preview_buffer holds replaced text
    @preview_buffer = app\new_buffer opts.editor.buffer.mode
    @preview_buffer.title = opts.preview_title or 'Preview Replacements'
    @preview_buffer.text = @text
    @preview_buffer.data.is_preview = true

    -- @buffer always holds original text
    @buffer = howl.Buffer!
    @buffer.collect_revisions = false
    @buffer.text = @text

    @start_pos = opts.editor.active_chunk.start_pos or 1
    @end_pos = opts.editor.active_chunk.end_pos or @buffer.length

    @runner = TaskRunner!

    self.find = opts.find or default_find
    self.replace = opts.replace or (match, replacement) -> replacement
    self.replacer_help = opts.help
    @command_line.title = opts.title or 'Replace'

    @orig_buffer = app.editor.buffer
    app.editor.buffer = @preview_buffer
    app.editor.line_at_top = @line_at_top

    @caption_widget = NotificationWidget!
    @command_line\add_widget 'caption_widget', @caption_widget

    @selected_idx = nil
    @num_matches = 0
    @num_replacements = 0
    @matches = {}
    @replacements = {}
    @replacements_applied = {}
    @strikeouts = {}
    @excluded = {}
    @num_excluded = 0
    @adjusted_positions = {}

    replace_command = (opts.replace_command or '') .. (@command_line\pop_spillover! or '')
    if replace_command.is_empty
      replace_command = '/'
    @command_line\write replace_command

    @on_update replace_command

  _restore_return: (result) =>
    @runner\cancel_all!
    app.editor.buffer = @orig_buffer
    app\close_buffer @preview_buffer, true
    self.finish result
    true

  on_update: (text) =>
    return if not text or text.is_empty

    marker = text[1]
    target, replacement = parse_replacement text\usub(2), marker

    refresh_matches = (target != @target) or (@replacement and not replacement)
    refresh_replacement = refresh_matches or (replacement != @replacement)

    @target = target
    @replacement = replacement

    if refresh_matches
      @_reload_matches!
    if refresh_replacement
      @_reload_replacements!

  _reload_matches: =>
    @runner\cancel_all!
    @runner\run 'reload-matches', (yield) ->
      if @num_replacements > 0
        @preview_buffer.text = @text
        app.editor.line_at_top = @line_at_top
      @matches = {}
      @num_matches = 0
      @replacements = {}
      @num_replacements = 0
      @replacements_applied = {}
      @adjusted_positions = {}
      @excluded = {}
      @selected_idx = nil
      preview_start = 1

      if @target and not @target.is_empty
        batch_start = @start_pos
        find = self.find
        for found_match in find @buffer, @target, @start_pos, @end_pos
          if found_match.end_pos > @end_pos
            break

          append @matches, found_match
          @num_matches += 1

          if (not @selected_idx) and (found_match.start_pos >= @orig_cursor_pos)
            @selected_idx = @num_matches

          if found_match.start_pos - batch_start > 64 * 1024
            batch_start = found_match.start_pos
            @_preview_replacements preview_start
            @_update_caption false, true
            preview_start = @num_matches + 1
            if yield!
              return

      if not @selected_idx and @num_matches > 0
        @selected_idx = 1

      @_preview_replacements preview_start
      @_update_caption!

  _reload_replacements: =>
    @runner\cancel 'submit'
    @runner\cancel 'reload-replacements'
    @runner\run 'reload-replacements', (yield) ->
      @replacements = {}
      @num_replacements = 0
      return unless @replacement

      batch_start = @start_pos
      preview_start = 1
      replace = self.replace
      replacement = @replacement
      for found_match in *@matches
        append @replacements, replace found_match, replacement
        @num_replacements += 1
        if found_match.start_pos - batch_start > 64 * 1024
          batch_start = found_match.start_pos
          @_preview_replacements preview_start
          @_update_caption true, false
          preview_start = @num_replacements + 1
          if yield!
            return

      @_preview_replacements preview_start
      @_update_caption!

  _update_caption: (match_finished=true, replace_finished=true) =>
    morem = match_finished and '' or '+'
    morer = replace_finished and '' or '+'
    local msg
    if @num_replacements == 0 and @num_excluded == 0
      msg = "Found #{@num_matches}#{morem} matches."
    else
      numr = math.max(0, @num_replacements - @num_excluded)
      msg = "Replacing #{numr}#{morer} of #{@num_matches}#{morem} matches."
    @caption_widget\notify 'comment', msg

  _preview_replacements: (start_idx=1, strikeout_removals=true) =>
    adjust = 0
    if @adjusted_positions[start_idx] and @matches[start_idx]
      adjust = @adjusted_positions[start_idx] - @matches[start_idx].start_pos

    matches = @matches
    replacements = @replacements

    pending = {}

    for i = start_idx, @num_matches
      match = matches[i]
      match_len = match.end_pos - match.start_pos + 1
      replacement = replacements[i]
      currently_applied = @replacements_applied[i]
      preview_pos = @adjusted_positions[i]
      @adjusted_positions[i] = match.start_pos + adjust

      if not replacement or @excluded[i]
        if currently_applied
          append pending,
            first: preview_pos
            last: preview_pos + currently_applied.ulen - 1
            text: @buffer\chunk(match.start_pos, match.end_pos).text

          @replacements_applied[i] = nil
        @strikeouts[i] = nil
      else
        if currently_applied != replacement
          len = currently_applied and currently_applied.ulen or match_len

          if replacement.is_empty and strikeout_removals
            replacement = @buffer\chunk(match.start_pos, match.end_pos).text
            @strikeouts[i] = true
          else
            @strikeouts[i] = nil

          append pending,
            first: preview_pos
            last: preview_pos + len - 1
            text: replacement
          @replacements_applied[i] = replacement
        adjust += replacement.ulen - match_len

    if #pending > 0
      first = pending[1].first
      last = pending[#pending].last
      substituted = {}
      for i, p in ipairs pending
        nextp = pending[i+1]
        append substituted, p.text
        if nextp
          append substituted, @preview_buffer\sub p.last + 1, nextp.first - 1
      app.editor\with_position_restored ->
        @preview_buffer\chunk(first, last).text = table.concat substituted

    @_preview_highlights!

  _preview_highlights: =>
    if @matches[@selected_idx]
      app.editor\ensure_visible @adjusted_positions[@selected_idx] or @matches[@selected_idx].start_pos
    else
      app.editor.line_at_top = @line_at_top

    first_visible = @preview_buffer.lines[math.max(1, app.editor.line_at_top - 5)].start_pos
    last_visible = @preview_buffer.lines[math.min(#@preview_buffer.lines, app.editor.line_at_bottom + 10)].end_pos

    @_clear_highlights!

    return unless @num_matches > 0

    -- skip until visible section
    local visible_start
    for i = 1, @num_matches
      match = @matches[i]
      preview_position = @adjusted_positions[i] or match.start_pos
      if preview_position >= first_visible
        visible_start = i
        break

    -- highlight visible section only
    return unless visible_start
    for i = visible_start, @num_matches
      match = @matches[i]
      preview_position = @adjusted_positions[i] or match.start_pos
      if preview_position > last_visible
        break
      hlt = @selected_idx == i and 'search' or 'search_secondary'
      len = @replacements_applied[i] and @replacements_applied[i].ulen or match.end_pos - match.start_pos + 1
      if @strikeouts[i]
        @_highlight_match 'replace_strikeout', preview_position, len
      else
        @_highlight_match hlt, preview_position, len

  _clear_highlights: (start_idx=1) =>
    highlight.remove_all 'search', @preview_buffer
    highlight.remove_all 'search_secondary', @preview_buffer
    highlight.remove_all 'replace_strikeout', @preview_buffer

  _highlight_match: (name, pos, len) =>
    highlight.apply name, @preview_buffer, pos, len

  _toggle_current: =>
    newval = not @excluded[@selected_idx]
    @excluded[@selected_idx] = newval
    @num_excluded += newval and 1 or -1
    @_preview_replacements @selected_idx
    @_update_caption!

  _switch_to: (cmd) =>
    captured_text = @command_line.text
    @command_line\run_after_finish ->
      app.editor.selection\select @start_pos, @end_pos
      command.run cmd .. ' ' .. captured_text
    @_restore_return!

  keymap:
    escape: => @_restore_return!

    alt_enter: => @_toggle_current!

    enter: => @runner\run 'submit', ->
      cursor_pos = @selected_idx and @matches[@selected_idx] and @matches[@selected_idx].start_pos
      result =
        num_replaced: @num_replacements - @num_excluded
        target: @target
        replacement: @replacement
        line_at_top: app.editor.line_at_top
        :cursor_pos

      if result.num_replaced > 0
        @_preview_replacements 1, false
        result.text = @preview_buffer.text

      @_restore_return result

    ctrl_r: => @_switch_to 'buffer-replace-regex'

    binding_for:
      ["cursor-down"]: =>
        return unless (@num_matches > 0) and @selected_idx
        if @selected_idx == @num_matches
          @selected_idx = 1
        else
          @selected_idx += 1
        @_preview_highlights!

      ["cursor-up"]: =>
        return unless (@num_matches > 0) and @selected_idx
        if @selected_idx == 1
          @selected_idx = @num_matches
        else
          @selected_idx -= 1
        @_preview_highlights!

      ['editor-scroll-up']: -> app.editor\scroll_up!
      ['editor-scroll-down']: -> app.editor\scroll_down!

      ['buffer-replace']: => @_switch_to 'buffer-replace'
      ['buffer-replace-regex']: => @_switch_to 'buffer-replace-regex'

  help: =>
    help = {
      {
        heading: "Syntax '/match/replacement'"
        text: markup.howl "Replaces occurences of <string>'match'</> with <string>'replacement'</>.
If match text contains <string>'/'</>, a different separator can be specified
by replacing the first character with the desired separator."
      }
      {
        key: 'up'
        action: 'Select previous match'
      }
      {
        key: 'down'
        action: 'Select next match'
      }
      {
        key: 'alt_enter'
        action: 'Toggle replacement for currently selected match'
      }
      {
        key: 'ctrl_r'
        action: 'Switch to buffer-replace-regex'
      }
      {
        key_for: 'buffer-replace'
        action: 'Switch to buffer-replace'
      }
      {
        key: 'enter'
        action: 'Apply replacements'
      }
    }
    if @replacer_help
      for item in *@replacer_help
        append help, item

    return help

interact.register
  name: 'get_replacement'
  description: 'Return text with user specified replacements applied'
  factory: Replacement

interact.register
  name: 'get_replacement_regex'
  description: 'Return text with user specified regex based replacements applied'
  handler: (opts) ->
    opts = moon.copy opts
    with opts
      .find = (buffer, target, start_pos=1, end_pos=buffer.length) ->
        ok, rex = pcall -> r('()' .. target .. '()')

        if not target or target.is_blank or not ok
          return ->

        line = buffer.lines\at_pos start_pos
        offset = start_pos - line.start_pos
        text = line.text\usub offset + 1
        if line.end_pos > end_pos
          text = text\usub 1, end_pos - line.end_pos
        matcher = rex\gmatch text

        return ->
          while line
            result = table.pack matcher!

            if #result> 0
              captures = {}
              for i=1, result.n - 2
                append captures, result[i+1]
              return {
                start_pos: line.start_pos + offset + result[1] - 1
                end_pos: line.start_pos + offset + result[result.n] - 2
                :captures
              }
            else
              line = line.next
              return unless line

              text = line.text
              if line.end_pos > end_pos
                text = text\usub 1, end_pos - line.end_pos

              matcher = rex\gmatch text
              offset = 0

      .replace = (match, replacement) ->
        if replacement
          result = replacement\gsub '(\\%d+)', (ref) ->
            ref_idx = tonumber(ref\sub(2))
            if ref_idx > 0
              return match.captures[ref_idx] or ''
            return ''
          return result

      .help = {
          {
            text: markup.howl "Here <string>'match'</> is a PCRE regular expression and <string>'replacement'</> is
text which may contain backreferences such as <string>'\\1'</string>"
          }
        }

    interact.get_replacement opts


