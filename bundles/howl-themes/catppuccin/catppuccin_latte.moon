{:delegate_to}  = howl.util.table

rosewater       = '#dc8a78'
flamingo        = '#dd7878'
pink            = '#ea76cb'
mauve           = '#8839ef'
red             = '#d20f39'
peach           = '#fe640b'
yellow          = '#df8e1d'
green           = '#40a02b'
teal            = '#179299'
sky             = '#04a5e5'
sapphire        = '#209fb5'
blue            = '#1e66f5'
lavender        = '#7287fd'
text            = '#4c4f69'
subtext1        = '#5c5f77'
subtext0        = '#6c6f85'
overlay2        = '#7c7f93'
overlay1        = '#8c8fa1'
overlay0        = '#9ca0b0'
surface2        = '#acb0be'
surface1        = '#bcc0cc'
surface0        = '#ccd0da'
base            = '#eff1f5'
mantle          = '#e6e9ef'
crust           = '#dce0e8'

black           = '#eff1f5'

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
      color: rosewater
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
      background: red
      background_alpha: 0.3
      text_color: text
      height: 'text'

    search_secondary:
      type: flair.ROUNDED_RECTANGLE
      background: teal
      background_alpha: 0.3
      text_color: text
      height: 'text'

    replace_strikeout:
      type: flair.ROUNDED_RECTANGLE
      foreground: text
      background: red
      background_alpha: 0.3
      text_color: subtext0
      height: 'text'

    brace_highlight:
      type: flair.RECTANGLE
      background: overlay2
      background_alpha: 0.3
      text_color: red
      height: 'text'

    brace_highlight_secondary:
      type: flair.RECTANGLE
      background: overlay2
      background_alpha: 0.3
      text_color: teal
      line_width: 1
      height: 'text'

    list_selection:
      type: flair.RECTANGLE
      background: overlay2
      background_alpha: 0.3

    list_highlight:
      type: highlight.UNDERLINE
      foreground: peach
      foreground_alpha: 0.3
      text_color: peach
      line_width: 2

    cursor:
      type: flair.RECTANGLE
      background: text
      width: 2
      height: 'text'

    block_cursor:
      type: flair.ROUNDED_RECTANGLE,
      background: text
      text_color: black
      height: 'text',
      min_width: 'letter'

    selection:
      type: highlight.ROUNDED_RECTANGLE
      background: overlay2
      background_alpha: 0.3
      min_width: 'letter'

  styles:
    default:
      color: text

    red: color: red
    green: color: green
    yellow: color: yellow
    blue: color: blue
    magenta: color: pink
    cyan: color: teal

    popup:
      background: surface0
      color: text

    comment:
      font: italic: true
      color: overlay2

    variable:
      color: blue

    label:
      color: subtext0
      font: italic: true

    key:
      color: blue
      font: bold: true

    fdecl:
      color: yellow
      font: bold: true

    keyword:
      color: mauve
      font: bold: true

    class:
      color: yellow
      font: bold: true

    type_def:
      color: yellow
      font:
        bold: true

    definition:
      color: yellow

    function:
      color: blue
      font: bold: true

    type:
      color: yellow
      font: italic: true

    char: color: green
    number: color: peach
    operator: color: sky
    preproc: color: rosewater
    special: color: red
    tag: color: maroon
    member: color: blue
    info: color: teal

    constant:
      color: peach

    string:
      color: green

    regex:
      color: pink

    embedded:
      color: red

    -- Markup and visual styles

    error:
      font: italic: true
      color: red
      background: red
      background_alpha: 0.3

    warning:
      font: italic: true
      color: peach
      background: peach
      background_alpha: 0.3

    info:
      font: italic: true
      color: teal
      background: teal
      background_alpha: 0.3


    h1:
      font: bold: true
      color: red

    h2:
      font: bold: true
      color: peach

    h3:
      font: italic: true
      color: yellow

    h4:
      font: italic: true
      color: green
    h5:
      font: italic: true
      color: sapphire
    h6:
      font: italic: true
      color: lavender

    emphasis:
      font:
        bold: true
        italic: true

    strong: font: italic: true
    link_label: color: green
    link_url: color: blue

    table:
      color: text
      background: mantle
      underline: true

    addition:
      color: green
      background: green
      background_alpha: 0.2
    deletion:
      color: red
      background: red
      background_alpha: 0.2
    change:
      color: blue
      background: blue
      background_alpha: 0.2
  }
