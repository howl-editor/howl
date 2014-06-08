background = '#002451'
current = '#00346e'
selection = '#0066cc'
foreground = '#ffffff'
comment = '#7285b7'
red = '#ff9da4'
orange = '#ffc58f'
yellow = '#ffeead'
green = '#d1f1a9'
aqua = '#99ffff'
blue = '#bbdaff'
purple = '#ebbbff'

embedded_bg = '#25384f'

return {
  window:
    background: 'dark_back.png'
    status:
      font: bold: true, italic: true
      color: grey

      info: color: blue
      warning: color: orange
      'error': color: red

  editor:
    border_color: '#333333'
    divider_color: darkblue

    header:
      background: [[
        -gtk-gradient (
          linear,
          left top, right top,
          from(#000022),to(#003080))
        ]]
      color: blue
      font: bold: true

    footer:
      background: '#002471'
      color: blue
      font: bold: true

    indicators:
      default:
        color: blue

      title:
        font: bold: true, italic: true

      vi:
        color: purple

    caret:
      color: lightgray
      width: 2

    current_line:
      background: current

    selection: background: selection

  highlights:
    search:
      style: highlight.ROUNDBOX
      color: white
      alpha: 80
      outline_alpha: 100

    list_selection:
      style: highlight.ROUNDBOX
      color: white
      outline_alpha: 100

  styles:

    default:
      :background
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

    variable: color: yellow

    label:
      color: orange
      font: italic: true

    line_number:
      color: comment
      :background

    key:
      color: blue
      font: bold: true

    fdecl:
      color: blue
      font: bold: true

    keyword:
      color: purple
      font: bold: true

    class:
      color: yellow
      font: bold: true

    definition: color: yellow

    function:
      color: blue
      font: bold: true

    char: color: green
    number: color: orange
    operator: color: aqua
    preproc: color: aqua
    special: color: purple
    tag: color: purple
    type: color: yellow
    member: color: red
    info: color: blue

    constant:
      color: yellow

    string: color: green

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

    list_highlight:
      color: white
      underline: true

    indentguide:
      :background
      color: foreground

    bracelight:
      color: foreground
      background: '#0064b1'

    bracebad:
      color: red

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
