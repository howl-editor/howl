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

return {
  window:
    background: 'dark_back.png'
    status:
      font: bold: true, italic: true
      color: grey

      info: color: blue
      warning: color: orange
      ['error']: color: red

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
      font: bold: true

    popup:
      background: '#00346e'
      color: foreground
      font: bold: true

    comment:
      font: italic: true
      color: comment

    error:
      font: italic: true
      color: white
      background: darkred

    warning:
      font: italic: true
      color: orange

    variable:
      color: red,
      font: italic: true

    label:
      color: orange
      font: italic: true

    line_number:
      color: comment
      :background

    bracelight:
      color: foreground
      background: '#0064b1'

    bracebad:
      color: red
      background: orange

    indentguide:
      :background
      color: foreground

    key: color: blue
    char: color: green
    keyword: color: purple
    class: color: yellow
    definition: color: yellow
    function: color: blue
    number: color: orange
    operator: color: aqua
    preproc: color: purple
    special: color: purple
    tag: color: purple
    type: color: red
    member: color: red
    embedded: color: purple
    info: color: blue
    constant: color: orange
    string: color: green
 }
