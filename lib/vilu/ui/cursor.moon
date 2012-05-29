import PropertyObject from vilu.aux.moon

class Cursor extends PropertyObject
  new: (sci) =>
    super!
    @sci = sci

  self\property pos:
    get: => 1 + @sci\get_current_pos!
    set: (pos) =>
      @sci\goto_pos pos - 1
      @sci\choose_caret_x!

  self\property line:
    get: => 1 + @sci\line_from_position @pos
    set: (line) => @pos = 1 + @sci\position_from_line(line - 1)

  self\property column:
    get: => 1 + @sci\get_column @pos - 1
    set: (col) => @pos = 1 + @sci\find_column @line - 1, col - 1

  key_commands = {
    down:             'line_down'
    up:               'line_up'
    left:             'char_left'
    right:            'char_right'
    word_left:        'word_right'
    word_left_end:    'word_left_end'
    word_part_left:   'word_part_left'
    word_right:       'word_right'
    word_right_end:   'word_right_end'
    word_part_right:  'word_part_right'
    home:             'home'
    home_vc:          'vchome'
    home_display:     'home_display'
    home_wrap:        'home_wrap'
    home_vc_wrap:     'vchome_wrap'
    end:              'line_end'
    end_display:      'line_end_display'
    end_wrap:         'line_end_wrap'
    start:            'document_start'
    eof:              'document_end'
    page_up:          'page_up'
    page_down:        'page_down'
    para_down:        'para_down'
    para_up:          'para_up'
  }
  for name, cmd in pairs key_commands
    self.__base[name] = => @sci[cmd] @sci

return Cursor
