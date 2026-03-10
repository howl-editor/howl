{:delegate_to} = howl.util.table

background   = '#282a36'
current      = '#44475a'
selection    = '#44475a'
foreground   = '#f8f8f2'
comment      = '#6272a4'

red          = '#ff5555'
orange       = '#ffb86c'
yellow       = '#f1fa8c'
green        = '#50fa7b'
aqua         = '#8be9fd'
blue         = '#8be9fd'
purple       = '#bd93f9'
magenta      = '#ff79c6'
grey         = '#595959'

grey_darker  = '#1c1d23'
grey_darkest = '#1c1d23'
grey_light   = '#a6a6a6'
embedded_bg  = '#484848'
border_color = '#44475a'

-- General styling for context boxes (editor, command_line)
content_box = {
  background:
    color: background

  border:
    width: 1
    color: border_color

  border_right:
    width: 3
    color: border_color

  border_bottom:
    width: 3
    color: border_color

  header:
    background:
      color: grey_darkest

    border_bottom:
      color: grey_darker

    color: white
    font: bold: true
    padding: 1

  footer:
    background:
      color: grey_darkest

    border_top:
      color: grey_darker

    color: grey
    font: bold: true
    padding: 1
}

return {
  window:
    background:
      color: background

    status:
      font: bold: true, italic: true
      color: grey

      info: color: grey_light
      warning: color: orange
      'error': color: red

  :content_box

  popup:
    background:
      color: grey_darkest
    border:
      color: grey

  editor: delegate_to content_box, {
    scrollbars:
      slider:
        color: magenta

    indicators:
      default:
        color: grey_light

      title:
        font: bold: true

      vi:
        font: bold: true

    caret:
      color: grey_light
      width: 2

    current_line:
      background: current

    gutter:
      color: comment
      background:
        color: grey_darkest
        alpha: 0.6
  }

  flairs:
    indentation_guide:
      type: flair.PIPE,
      foreground: comment,
      :background,
      line_width: 1

    indentation_guide_1:
      type: flair.PIPE,
      foreground: grey_darker,
      line_width: 1

    indentation_guide_2:
      type: flair.PIPE,
      foreground: grey_darker,
      line_width: 1

    indentation_guide_3:
      type: flair.PIPE,
      foreground: grey_darker,
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
      background: yellow
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

    brace_highlight_secondary:
      type: flair.RECTANGLE
      foreground: '#0064b1'
      text_color: foreground
      line_width: 1
      height: 'text'

    list_selection:
      type: flair.RECTANGLE
      background: current
      background_alpha: 0.3

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
      background_alpha: 0.4
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
      background: grey_darkest
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
      color: blue
      background: embedded_bg

    -- Markup and visual styles

    error:
      font: italic: true
      color: white
      background: red

    warning:
      font: italic: true
      color: orange

    h1:
      font: bold: true
      color: magenta

    h2:
      font: bold: true
      color: aqua

    h3:
      font: italic: true
      color: purple

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
