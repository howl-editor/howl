{:delegate_to}  = howl.util.table

rosewater       = '#f4dbd6'
flamingo        = '#f0c6c6'
pink            = '#f5bde6'
mauve           = '#c6a0f6'
red             = '#ed8796'
peach           = '#f5a97f'
yellow          = '#eed49f'
green           = '#a6da95'
teal            = '#8bd5ca'
sky             = '#91d7e3'
sapphire        = '#7dc4e4'
blue            = '#8aadf4'
lavender        = '#b7bdf8'
text            = '#cad3f5'
subtext1        = '#b8c0e0'
subtext0        = '#a5adcb'
overlay2        = '#939ab7'
overlay1        = '#8087a2'
overlay0        = '#6e738d'
surface2        = '#5b6078'
surface1        = '#494d64'
surface0        = '#363a4f'
base            = '#24273a'
mantle          = '#1e2030'
crust           = '#181926'

-- General styling for context boxes (editor, command_line)
content_box = {
  background:
    color: base

  border:
    width: 1
    color: overlay0

  border_right:
    width: 3
    color: overlay0

  border_bottom:
    width: 3
    color: overlay0

  header:
    background:
      color: mantle

    border_bottom:
      color: overlay0

    color: text
    font: bold: true
    padding: 1

  footer:
    background:
      color: mantle

    border_top:
      color: overlay0

    color: text
    font: bold: true
    padding: 1
}

return {
  window:
    background:
      color: base

    status:
      font: bold: true, italic: true
      color: subtext0

      info: color: teal
      warning: color: peach
      'error': color: red

  :content_box

  popup:
    background:
      color: surface0
    border:
      color: lavender

  editor: delegate_to content_box, {
    scrollbars:
      slider:
        color: overlay2

    indicators:
      default:
        color: subtext0

      title:
        font: bold: true

      vi:
        font: bold: true

    caret:
      color:
      width: 2

    current_line:
      background: overlay2

    gutter:
      color: subtext1
      background:
        color: mantle
        alpha: 0.6
  }

  flairs:
    indentation_guide:
      type: flair.PIPE,
      foreground: overlay2,
      :background,
      line_width: 1

    indentation_guide_1:
      type: flair.PIPE,
      foreground: surface1,
      line_width: 1

    indentation_guide_2:
      type: flair.PIPE,
      foreground: surface1,
      line_width: 1

    indentation_guide_3:
      type: flair.PIPE,
      foreground: surface1,
      line_width: 1

    edge_line:
      type: flair.PIPE,
      foreground: overlay0,
      line_width: 0.5

    search:
      type: highlight.ROUNDED_RECTANGLE
      foreground: text
      foreground_alpha: 1
      background: red
      text_color: text
      height: 'text'

    search_secondary:
      type: flair.ROUNDED_RECTANGLE
      background: yellow
      text_color:
      height: 'text'

    replace_strikeout:
      type: flair.ROUNDED_RECTANGLE
      foreground: black
      background: red
      text_color:
      height: 'text'

    brace_highlight:
      type: flair.RECTANGLE
      text_color:
      background: overlay2
      background_alpha: 0.3
      height: 'text'

    brace_highlight_secondary:
      type: flair.RECTANGLE
      foreground:
      text_color:
      background: overlay2
      background_alpha: 0.3
      line_width: 1
      height: 'text'

    list_selection:
      type: flair.RECTANGLE
      background: overlay2
      background_alpha: 0.3

    list_highlight:
      type: highlight.UNDERLINE
      foreground: white
      text_color:
      line_width: 2

    cursor:
      type: flair.RECTANGLE
      background: foreground
      width: 2
      height: 'text'

    block_cursor:
      type: flair.ROUNDED_RECTANGLE,
      background: foreground
      text_color:
      height: 'text',
      min_width: 'letter'

    selection:
      type: highlight.ROUNDED_RECTANGLE
      background: overlay2
      background_alpha: 0.3
      min_width: 'letter'

  styles:
    default:
      color:

    red: color:
    green: color:
    yellow: color:
    blue: color:
    magenta: color:
    cyan: color:

    popup:
      background: grey_darkest
      color:

    comment:
      font: italic: true
      color:

    variable:
      color:

    label:
      color:
      font: italic: true

    key:
      color:
      font: bold: true

    fdecl:
      color:
      font: bold: true

    keyword:
      color:
      font: bold: true

    class:
      color:
      font: bold: true

    type_def:
      color:
      font:
        bold: true

    definition:
      color:

    function:
      color:
      font: bold: true

    type:
      color:
      font: italic: true

    char: color:
    number: color:
    operator: color:
    preproc: color:
    special: color:
    tag: color:
    member: color:
    info: color:

    constant:
      color:

    string:
      color:

    regex:
      color:
      background: embedded_bg

    embedded:
      color:
      background: embedded_bg

    -- Markup and visual styles

    error:
      font: italic: true
      color:
      background: red

    warning:
      font: italic: true
      color:

    h1:
      font: bold: true
      color:

    h2:
      font: bold: true
      color:

    h3:
      font: italic: true
      color:

    emphasis:
      font:
        bold: true
        italic: true

    strong: font: italic: true
    link_label: color:
    link_url: color:

    table:
      color:
      background: embedded_bg
      underline: true

    addition: color:
    deletion: color:
    change: color:
  }
