{:delegate_to} = howl.util.table

base1   = '#93a1a1'
base2  = '#eee8d5'
base3   = '#fdf6e3'
base00  = '#657b83'
base01  = '#586e75'
base02  = '#073642'
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
operator = base00
member = base02
key = blue

-- General styling for context boxes (editor, command_line)
content_box = {
  background:
    color: background

  border:
    width: 1
    color: base1

  border_right:
    width: 3
    color: base1

  border_bottom:
    width: 3
    color: base1

  header:
    background:
      image:
        path: theme_file('sprinkles.png')

    border_bottom:
      color: base1

    color: brown
    font: bold: true
    padding: 1

  footer:
    background:
      color: base2

    border_top:
      color: base1

    color: brown
    font: bold: true
    padding: 1
}

return {
  window:
    background:
      image:
        path: theme_file('lightpaperfibers.png')
    status:
      font: bold: true, italic: true
      color: blue

      info: color: green
      warning: color: orange
      error: color: red

  :content_box

  popup: {
    background:
      color: current

    border:
      color: base1
      alpha: 0.5
  }

  editor: delegate_to content_box, {
    indicators:
      default:
        color: yellow

      title:
        color: yellow
        font: bold: true, italic: true

    current_line:
      background: current

    gutter:
      color: base1
      background:
        color: base2
        alpha: 0.7
  }

  flairs:
    indentation_guide:
      type: flair.PIPE,
      foreground: '#aaaaaa',
      line_type: 'dotted'
      line_width: 1

    indentation_guide_1:
      type: flair.PIPE,
      foreground: blue,
      foreground_alpha: 0.3
      line_width: 1

    indentation_guide_2:
      type: flair.PIPE,
      foreground: green,
      foreground_alpha: 0.4
      line_width: 1

    indentation_guide_3:
      type: flair.PIPE,
      foreground: green,
      line_type: 'dotted'
      line_width: 1

    edge_line:
      type: flair.PIPE,
      foreground: green,
      foreground_alpha: 0.3,
      line_type: 'solid'
      line_width: 0.5

    search:
      type: highlight.ROUNDED_RECTANGLE
      foreground: darkgreen
      foreground_alpha: 1
      background: blue
      text_color: white
      height: 'text'

    search_secondary:
      foreground: lightblue
      line_width: 1
      type: highlight.ROUNDED_RECTANGLE
      background: black
      background_alpha: 0.6
      text_color: white
      height: 'text'

    replace_strikeout:
      type: highlight.ROUNDED_RECTANGLE
      foreground: black
      background: red
      text_color: lightgray
      background_alpha: 0.7
      height: 'text'

    brace_highlight:
      type: highlight.ROUNDED_RECTANGLE
      text_color: white
      background: blue
      background_alpha: 0.6
      height: 'text'

    brace_highlight_secondary:
      type: highlight.RECTANGLE
      foreground: blue
      line_width: 1
      height: 'text'

    list_selection:
      type: highlight.RECTANGLE
      foreground: blue
      foreground_alpha: 0.5
      background: blue
      background_alpha: 0.2

    list_highlight:
      type: highlight.UNDERLINE
      text_color: black
      line_width: 2

    cursor:
      type: highlight.RECTANGLE
      background: base01
      width: 2
      height: 'text'

    block_cursor:
      type: highlight.RECTANGLE,
      background: base01
      text_color: background
      height: 'text',
      min_width: 'letter'

    selection:
      type: highlight.ROUNDED_RECTANGLE
      background: selection
      background_alpha: 0.6
      min_width: 'letter'

  styles:

    default:
      color: black

    red: color: red
    green: color: green
    yellow: color: yellow
    blue: color: blue
    magenta: color: magenta
    cyan: color: cyan

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
    wrap_indicator: 'blue'

    fdecl:
      color: key
      font: bold: true

    keyword:
      color: keyword
      font: bold: true

    class:
      color: class_name
      font:
        bold: true

    type_def:
      color: class_name
      font:
        bold: true
        size: 'large'
        family: 'Purisa,Latin Modern Sans'

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
      background: wheat
      color: black

    -- Markup and visual styles

    error:
      font:
        italic: true
        bold: true
      color: red

    warning:
      font: italic: true
      color: orange

    h1:
      color: white
      background: yellow
      font: bold: true

    h2:
      color: white
      background: comment

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
      color: black
      underline: true

    addition: color: green
    deletion: color: red
    change: color: yellow
  }
