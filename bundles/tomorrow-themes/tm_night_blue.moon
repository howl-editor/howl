background = '#002451'
current = '#00346e'
selection = '#003f8e'
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

  view:
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
      font:
        name: 'Liberation Mono'
        size: 11
        bold: true

      indicators:
        title:
          font:
            name: 'Liberation Mono'
            size: 11
            bold: true
            italic: true

    footer:
      background: '#002471'
      color: blue
      font:
        name: 'Liberation Mono'
        size: 11

    caret:
      color: lightgray
      width: 2

    current_line:
      background: current

    selection: background: selection

  styles:
    default:
      :background
      color: foreground
      font:
        name: '!Liberation Mono'
        size: 11
        bold: true

    comment:
      font: italic: true
      color: comment

    constant: color: orange

    string:
      font: italic: true
      color: green

    longstring:
      font: italic: true
      color: green

    char: color: green

    keyword: color: purple

    class: color: yellow

    definition: color: yellow

    error:
      font: italic: true
      color: red

    function: color: blue

    number: color: orange

    operator: color: aqua

    preproc: color: purple

    tag: color: purple

    type: color: red

    variable:
      color: red,
      font: italic: true

    embedded: color: purple

    label:
      color: orange
      font: italic: true

    line_number:
      color: comment
      :background

    bracelight: color: blue

    bracebad:
      color: red
      background: orange

    indentguide:
      :background
      color: foreground

}
