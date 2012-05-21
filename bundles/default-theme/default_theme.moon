background = '#f0f0f3'

return {
  name: 'Default'

  window:
    background: 'default_back.png'

  view:
    border_color: '#000000'

    header:
      background: [[
        -gtk-gradient (
          linear,
          left top, right top,
          from(#eee),to(#999))
        ]]
      border_color: '#000000'
      color: 'darkgrey'
      font:
        name: 'Liberation Mono'
        size: 11
        bold: true

      indicators:

        title:
          font:
            name: 'Liberation Mono'
            size: 12
            bold: true
            italic: true

    caret:
      color: '#222222'
      width: 2

  styles:

    default:
      :background
      color: '#241f1c'
      font:
        name: '!Liberation Mono'
        size: 11
        bold: true

    comment:
      font: italic: true
      color: '#008b8b'

    constant:
      color: "#a09e5f"

    string:
      font: italic: true
      color: '#4080c0'

    longstring:
      font: italic: true
      color: '#4080c0'

    char:
      color: '#4080c0'

    keyword:
      color: '#000099'

    class:
      color: '#4080c0'

    definition:
      color: '#994C4C'

    error:
      font: italic: true
      color: '#994C4C'

    function:
      color: '#c08040'

    number:
      color: '#c08040'

    operator:
      color: '#4D9999'

    preproc:
      color: '#994C4C'

    tag:
      color: '#4080C0'

    type:
      color: '#4080C0'

    variable:
      color: '#4D9999'
      font: italic: true

    embedded:
      color: '#4080C0'
      background: '#444444'

    label:
      color: '#4D9999'
      font: italic: true

    line_number:
      color: '#4d4d4d'
      :background
      font: italic: true

    bracelight:
      color: '#00ffff'

    bracebad:
      color: '#aaaaaa'
      background: '#994c4c'

}
