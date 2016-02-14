background   = '#272822'
current      = '#75715e'
selection    = '#0066cc'
foreground   = '#ffffff'
comment      = '#75715e'
red          = '#ff9da4'
orange       = '#ffc58f'
yellow       = '#e6db74'
yellow_dark  = '#75715e'
green        = '#a6e22a'
aqua         = '#99ffff'
blue         = '#89bdff'
purple       = '#ae81ff'
magenta      = '#f92672'
grey         = '#595959'
grey_darker  = '#383830'
grey_darkest = '#303024'
grey_light   = '#a6a6a6'
embedded_bg  = '#25389f'

return {
  window:
    :background
    status:
      font: bold: true, italic: true
      color: grey

      info: color: grey_light
      warning: color: orange
      'error': color: red

  editor:
    border_color: '#333333'
    divider_color: grey_darker
    :background

    header:
      background: grey_darkest
      color: white
      font: bold: true

    footer:
      background: grey_darker
      color: grey
      font: bold: true

    indicators:
      default:
        color: grey_light

      title:
        font: bold: true

      vi:
        color: purple

    caret:
      color: lightgray
      width: 2

    current_line:
      background: current

    gutter:
      foreground: comment
      background: grey_darkest

  flairs:
    indentation_guide:
      type: flair.PIPE,
      foreground: comment,
      :background,
      line_width: 1

    indentation_guide_1:
      type: flair.PIPE,
      foreground: blue,
      foreground_alpha: 0.5
      line_width: 1

    indentation_guide_2:
      type: flair.PIPE,
      foreground: green,
      foreground_alpha: 0.5
      line_width: 1

    indentation_guide_3:
      type: flair.PIPE,
      foreground: green,
      foreground_alpha: 0.3
      line_width: 1

    edge_line:
      type: flair.PIPE,
      foreground: blue,
      foreground_alpha: 0.3,
      line_width: 0.5

    search:
      type: highlight.ROUNDED_RECTANGLE
      foreground: black
      foreground_alpha: 1
      background: yellow
      text_color: grey_darkest
      height: 'text'

    search_secondary:
      type: flair.ROUNDED_RECTANGLE
      background: yellow_dark
      text_color: grey_darkest
      height: 'text'

    replace_strikeout:
      type: flair.ROUNDED_RECTANGLE
      foreground: black
      background: red
      text_color: black
      height: 'text'

    brace_highlight:
      type: flair.RECTANGLE
      text_color: foreground
      background: '#0064b1'
      height: 'text'

    list_selection:
      type: flair.RECTANGLE
      background: white
      background_alpha: 0.4

    list_highlight:
      type: highlight.UNDERLINE
      foreground: white
      text_color: white
      line_width: 2

    cursor:
      type: flair.RECTANGLE
      background: foreground
      width: 2
      height: 'text'

    block_cursor:
      type: flair.ROUNDED_RECTANGLE,
      background: foreground
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
      color: foreground

    red: color: red
    green: color: green
    yellow: color: yellow
    blue: color: blue
    magenta: color: purple
    cyan: color: aqua

    popup:
      background: '#00346e'
      color: foreground

    comment:
      font: italic: true
      color: comment

    variable:
      color: yellow

    label:
      color: orange
      font: italic: true

    key:
      color: blue
      font: bold: true

    fdecl:
      color: green
      font: bold: true

    keyword:
      color: magenta
      font: bold: true

    class:
      color: blue
      font: bold: true

    type_def:
      color: green
      font:
        bold: true

    identifier:
      color: white

    definition:
      color: yellow

    function:
      color: blue
      font: bold: true

    type:
      color: blue
      font: italic: true

    char: color: green
    number: color: purple
    operator: color: magenta
    preproc: color: aqua
    special: color: purple
    tag: color: purple
    member: color: red
    info: color: blue

    constant:
      color: yellow

    string:
      color: yellow

    regex:
      color: green
      background: embedded_bg

    embedded:
      color: '#aadaff'
      background: embedded_bg
      eol_filled: true

    -- Markup and visual styles

    error:
      font: italic: true
      color: white
      background: darkred

    warning:
      font: italic: true
      color: orange

    h1:
      color: white
      background: '#005491'

    h2:
      color: green
      font: bold: true

    h3:
      color: purple
      background: current
      font: italic: true

    emphasis:
      font:
        bold: true
        italic: true

    strong: font: italic: true
    link_label: color: aqua
    link_url: color: comment

    table:
      color: blue
      background: embedded_bg
      underline: true

    addition: color: green
    deletion: color: red
    change: color: yellow
  }
