import PropertyObject from lunar.aux.moon
import Scintilla from lunar

class Cursor extends PropertyObject
  new: (sci, selection) =>
    super!
    @sci = sci
    @selection = selection

  @property blink_interval:
    get: => @sci\get_caret_period!
    set: (interval) => @sci\set_caret_period interval

  @property style:
    get: =>
      cur_style = @sci\get_caret_style!
      if cur_style == Scintilla.CARETSTYLE_BLOCK then return 'block'
      elseif cur_style == Scintilla.CARETSTYLE_LINE then return 'line'
    set: (style) =>
      if style == 'block'
        @sci\set_caret_style Scintilla.CARETSTYLE_BLOCK
        @selection.includes_cursor = true
      elseif style == 'line'
        @sci\set_caret_style Scintilla.CARETSTYLE_LINE
        @selection.includes_cursor = false
      else error 'Invalid style ' .. style, 2

  @property pos:
    get: => 1 + @sci\get_current_pos!
    set: (pos) =>
      if @selection.persistent
        @selection\set @selection.anchor, pos
      else
        @sci\goto_pos pos - 1
      @sci\choose_caret_x!

  @property line:
    get: => 1 + @sci\line_from_position @pos - 1
    set: (line) =>
      if line < 1 then @start!
      elseif line > @sci\get_line_count! then @eof!
      else @pos = 1 + @sci\position_from_line(line - 1)

  @property column:
    get: => 1 + @sci\get_column @pos - 1
    set: (col) => @pos = 1 + @sci\find_column @line - 1, col - 1

  @property at_end_of_line:
    get: =>
      cur_pos = @pos
      @sci\get_line_end_position(@line - 1) == cur_pos - 1

  _adjust_persistent_selection_if_needed: =>
    return unless @selection.persistent and @selection.includes_cursor
    selection_start = @selection.persistent_anchor
    correct_anchor = @selection.cursor < selection_start and selection_start + 1 or selection_start
    @selection.anchor = correct_anchor if @selection.anchor != correct_anchor

  key_commands = {
    down:             'line_down'
    up:               'line_up'
    left:             'char_left'
    right:            'char_right'
    word_left:        'word_left'
    word_left_end:    'word_left_end'
    word_part_left:   'word_part_left'
    word_right:       'word_right'
    word_right_end:   'word_right_end'
    word_part_right:  'word_part_right'
    home:             'home'
    home_vc:          'vchome'
    home_vc_display:  'vchome_display'
    home_display:     'home_display'
    home_wrap:        'home_wrap'
    home_vc_wrap:     'vchome_wrap'
    line_end:         'line_end'
    line_end_display: 'line_end_display'
    line_end_wrap:    'line_end_wrap'
    start:            'document_start'
    eof:              'document_end'
    page_up:          'page_up'
    page_down:        'page_down'
    para_down:        'para_down'
    para_up:          'para_up'
  }
  for name, cmd in pairs key_commands
    plain = Scintilla[cmd]
    extended = Scintilla[cmd .. '_extend']

    self.__base[name] = (extend_selection) =>
      if extend_selection or @selection.persistent
        extended @sci
        @_adjust_persistent_selection_if_needed!
      else
        plain @sci

return Cursor
