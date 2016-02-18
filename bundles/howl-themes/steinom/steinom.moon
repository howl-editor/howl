 --Copyright 2016 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

{:delegate_to} = howl.util.table

orange = '#bf954f'
aqua = '#85E0DC'
purple = '#886CD6'
yellow = '#CED0AD'
green = '#6Ac081'
darkblue = '#567DB3'
lightblue = '#81A7C9'
red = '#D67C73'
foreground = '#dddddd'
base = '#222222'
border_flair = '#808080'

embedded_bg = lightgray
comment = grey

-- General styling for context boxes (editor, command_line)
content_box = {

  border:
    width: 2
    color: slategray
    alpha: 0.3
    radius: 10

  header:
    color: foreground
    padding_top: 5
    padding_bottom: 2
    background:
      image:
        path: theme_file('escheresque_ste.png')

      gradient:
        type: 'linear'
        direction: 'vertical'
        stops: { gray, base, base, base, base }
        alpha: 0.3

  footer: {
    color: foreground
    padding: 1
    background:
      gradient:
        type: 'linear'
        direction: 'horizontal'
        stops: { black, base, border_flair, base, black }
        alpha: 0.2
  }
}

return {
  window:
    outer_padding: 5
    background:
      image:
        path: theme_file('footer_lodyas.png')

    status:
      font: bold: true, italic: true
      color: grey

      info: color: lightblue
      warning: color: orange
      'error': color: red

  :content_box

  popup:
    background:
      color: '#555555'
      alpha: 0.95
    border:
      color: gray

  editor: delegate_to content_box, {
    indicators:
      default:
        color: slategray

      title:
        font: bold: true
        color: lightblue

      vi:
        font: bold: true

    gutter:
      color: gray
      background:
        gradient:
          type: 'linear'
          direction: 'vertical'
          stops: { black, base, border_flair, black }
          alpha: 0.2
    }

  flairs:
    indentation_guide:
      type: flair.PIPE
      foreground: comment
      line_width: 1
      foreground_alpha: 0.5

    indentation_guide_1:
      type: flair.PIPE
      foreground: lightblue
      foreground_alpha: 0.5
      line_width: 1

    indentation_guide_2:
      type: flair.PIPE
      foreground: green
      foreground_alpha: 0.5
      line_width: 1

    indentation_guide_3:
      type: flair.PIPE
      foreground: green
      foreground_alpha: 0.3
      line_width: 1

    edge_line:
      type: flair.PIPE
      foreground: base
      line_width: 2
      foreground_alpha: 0.2,

    search:
      type: highlight.ROUNDED_RECTANGLE
      foreground: cyan
      background: cyan
      background_alpha: 0.5
      text_color: white
      height: 'text'

    search_secondary:
      type: flair.ROUNDED_RECTANGLE
      background: lightgrey
      background_alpha: 0.3
      text_color: lightblue
      height: 'text'

    replace_strikeout:
      type: flair.ROUNDED_RECTANGLE
      foreground: lightgrey
      background: red
      background_alpha: 0.5
      text_color: red
      height: 'text'

    brace_highlight:
      type: flair.RECTANGLE
      text_color: foreground
      background: '#0064b1'
      height: 'text'

    list_selection:
      type: flair.ROUNDED_RECTANGLE
      background: slategray
      background_alpha: 0.4

    list_highlight:
      type: highlight.UNDERLINE
      foreground: lightgray
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
      text_color: base
      height: 'text',
      min_width: 'letter'

    selection:
      type: highlight.ROUNDED_RECTANGLE
      background: darkblue
      background_alpha: 0.3
      min_width: 'letter'

  styles:

    default:
      color: foreground

    red: color: red
    green: color: green
    yellow: color: yellow
    blue: color: lightblue
    magenta: color: purple
    cyan: color: aqua

    comment:
      font: italic: true
      color: comment

    variable: color: yellow

    label:
      color: orange
      font: italic: true

    key:
      color: lightblue
      font: bold: true

    fdecl:
      color: lightblue
      font: bold: true

    keyword:
      color: lightblue
      font: bold: true

    class:
      color: yellow
      font: bold: true

    type_def:
      color: yellow
      font:
        bold: true
        size: 'large'
        family: 'Purisa,Latin Modern Sans'

    definition: color: yellow

    function:
      color: lightgrey
      font: bold: true

    char: color: green
    number: color: orange
    operator: color: '#85E0DC'
    preproc: color: darkblue
    special:
      color: darkblue
      font: bold: true
    tag: color: purple
    type: color: red
    member: color: yellow
    info: color: lightblue
    constant: color: yellow
    string: color: green

    regex:
      color: green
      background: embedded_bg
      background_alpha: 0.1

    embedded:
      color: foreground
      background: lightblue
      background_alpha: 0.2

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
      background: lightblue
      background_alpha: 0.4
      font:
        family: 'Purisa,Latin Modern Sans'
        size: 'large'
        bold: true

    h2:
      color: yellow
      font: bold: true

    h3:
      color: lightblue
      font: italic: true

    emphasis:
      font:
        bold: true
        italic: true

    strong: font: italic: true
    link_label: color: aqua
    link_url: color: comment

    table:
      color: lightblue
      background: embedded_bg
      background_alpha: 0.2
      underline: true

    addition: color: green
    deletion: color: red
    change: color: yellow
  }
