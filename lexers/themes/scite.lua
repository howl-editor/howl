-- Copyright 2006-2012 Mitchell mitchell.att.foicica.com. See LICENSE.
-- SciTE lexer theme for Scintillua.

local l, color, style = lexer, lexer.color, lexer.style

l.colors = {
  red = color('7F', '00', '00'),
  yellow = color('7F', '7F', '00'),
  green = color('00', '7F', '00'),
  teal = color('00', '7F', '7F'),
  purple = color('7F', '00', '7F'),
  orange = color('B0', '7F', '00'),
  blue = color('00', '00', '7F'),
  black = color('00', '00', '00'),
  grey = color('80', '80', '80'),
  white = color('FF', 'FF', 'FF'),
}

l.style_nothing     = style {                                    }
l.style_class       = style { fore = l.colors.black, bold = true }
l.style_comment     = style { fore = l.colors.green              }
l.style_constant    = style { fore = l.colors.teal, bold = true  }
l.style_definition  = style { fore = l.colors.black, bold = true }
l.style_error       = style { fore = l.colors.red                }
l.style_function    = style { fore = l.colors.black, bold = true }
l.style_keyword     = style { fore = l.colors.blue, bold = true  }
l.style_number      = style { fore = l.colors.teal               }
l.style_operator    = style { fore = l.colors.black, bold = true }
l.style_string      = style { fore = l.colors.purple             }
l.style_preproc     = style { fore = l.colors.yellow             }
l.style_tag         = style { fore = l.colors.teal               }
l.style_type        = style { fore = l.colors.blue               }
l.style_variable    = style { fore = l.colors.black              }
l.style_embedded    = style { fore = l.colors.blue               }
l.style_label       = style { fore = l.colors.teal, bold = true  }
l.style_regex       = l.style_string
l.style_identifier  = l.style_nothing

-- Default styles.
local font_face = '!Monospace'
local font_size = 11
if WIN32 then
  font_face = not GTK and 'Courier New' or '!Courier New'
elseif OSX then
  font_face = '!Monaco'
  font_size = 12
end
l.style_default = style {
  font = font_face,
  size = font_size,
  fore = l.colors.black,
  back = l.colors.white,
}
l.style_line_number = style { back = color('C0', 'C0', 'C0') }
l.style_bracelight  = style { fore = color('00', '00', 'FF'), bold = true }
l.style_bracebad    = style { fore = color('FF', '00', '00'), bold = true }
l.style_controlchar = style_nothing
l.style_indentguide = style { fore = color('C0', 'C0', 'C0'), back = l.colors.white }
l.style_calltip     = style { fore = l.colors.white, back = color('44', '44', '44') }
