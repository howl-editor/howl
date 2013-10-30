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
    background: 'lightpaperfibers.png'
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
      background: 'sprinkles.png'
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
      style: highlight.ROUNDBOX
      color: blue
      alpha: 80
      outline_alpha: 100

    list_selection:
      style: highlight.ROUNDBOX
      color: blue
      alpha: 40
      outline_alpha: 100

  styles:

    default:
      :background
      color: foreground

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
    regex: color: green

    embedded:
      background: wheat
      color: foreground

    -- Markup and visual styles

    error:
      font: italic: true
      color: white
      background: darkred

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
      color: red
      background: orange

    h1:
      color: white
      background: yellow
      eol_filled: true
      font: size: 'larger'

    h2:
      color: white
      background: comment
      font: size: 'large'

    h3:
      color: violet
      background: current
      font: italic: true

    strong:
      color: aqua
      font: bold: true

    emphasis:
      font:
        italic: true
        bold: true

    link_label: color: aqua
    link_url: underline: true

    addition: color: green
    deletion: color: red
    change: color: yellow
  }
