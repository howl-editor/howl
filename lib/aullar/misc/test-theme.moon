base0   = '#839496'
base1   = '#93a1a1'
base2  = '#eee8d5'
base3   = '#fdf6e3'
base00  = '#657b83'
base01  = '#586e75'
base02  = '#073642'
base03  = '#002b36'
yellow  = '#b58900'
orange  = '#cb4b16'
red     = '#dc322f'
magenta = '#d33682'
violet  = '#6c71c4'
blue    = '#268bd2'
cyan    = '#2aa198'
green   =  '#859900'

background = base3
current = base2
selection = lightblue
comment = base1
string = cyan
number = blue
keyword = green
class_name = yellow
special = orange
operator = base00
member = base02
key = blue

return {
  window:
    background: 'wolf-print.jpg'

    status:
      font: bold: true, italic: true
      color: blue

      info: color: green
      warning: color: orange
      'error': color: red

  editor:
    border_color: base1
    divider_color: base1

    header:
      background: black
      color: brown
      font: bold: true

    footer:
      background: base2
      color: brown
      font: bold: true

    indicators:
      default:
        color: yellow

      title:
        color: yellow
        font: bold: true, italic: true

    caret:
      color: base01
      width: 2

    current_line:
      background: current

    selection: background: selection

  highlights:
    search:
      type: highlight.RECTANGLE
      foreground: darkgreen
      foreground_alpha: 1
      background: darkgreen
      background_alpha: 0.4

    search_secondary:
      type: highlight.UNDERLINE
      foreground: green
      line_width: 2

    list_selection:
      type: highlight.RECTANGLE
      foreground: blue
      alpha: 40
      outline_alpha: 100

  styles:

    default:
      :background
      color: foreground

    red: color: red
    green: color: green
    yellow: color: yellow
    blue: color: blue
    magenta: color: magenta
    cyan: color: cyan

    popup:
      background: current
      color: foreground

    comment:
      font: italic: true
      color: comment

    variable: color: yellow

    label:
      color: orange
      font: italic: true

    line_number:
      color: base1
      background: base2

    key:
      color: key
      font: bold: true

    char: color: green

    fdecl:
      color: key
      font: bold: true

    keyword:
      color: keyword
      font: bold: true

    class:
      color: class_name
      font: bold: true

    definition: color: yellow
    function: color: blue

    number:
      color: number
      font: bold: true

    operator:
      color: operator
      font: bold: true

    preproc: color: red

    special:
      color: cyan
      font: bold: true

    tag: color: purple

    type:
      color: class_name
      font: bold: true

    member:
      color: member
      font: bold: true

    info: color: blue
    constant: color: orange
    string: color: string

    regex:
      color: green
      background: wheat

    embedded:
      background: '#99CCFF'
      color: foreground
      eol_filled: true

    -- Markup and visual styles

    error:
      font:
        italic: true
        bold: true
      color: red

    warning:
      font: italic: true
      color: orange

    list_highlight:
      color: foreground
      underline: true
      font: bold: true

    indentguide:
      :background
      color: foreground

    bracelight:
      color: white
      background: blue

    bracebad:
      color: white
      background: orange

    h1:
      color: white
      background: yellow
      eol_filled: true
      font:
        bold: true
        size: 24

    h2:
      color: white
      background: comment
      font:
        size: 18
        italic: true

    h3:
      color: violet
      background: current
      font: italic: true

    emphasis:
      font:
        bold: true
        italic: true

    strong: font: italic: true

    link_label:
      color: blue
      underline: true

    link_url:
      color: comment

    table:
      background: wheat
      color: foreground
      underline: true

    addition: color: green
    deletion: color: red
    change: color: yellow
  }
