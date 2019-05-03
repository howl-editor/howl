{:delegate_to} = howl.util.table

light_grey = '#E1EEF6'
dark_blue = '#003A4c'
dark_blue_off = '#336170'
deep_dark_blue = '#002F3D'
orange = '#FF5F2E'
yellow = '#FCBE32'

grey = '#888'
blue = '#738DFC'
red = '#B23610'
light_red = '#FF9F8F'
magenta = '#D33682'
cyan = '#2AA198'
green = '#00B284'
purple = '#C687FF'

background = dark_blue
current = grey

selection = lightblue

string = green
number = green

operator = yellow
keyword = yellow
class_name = blue

special = green
key = orange

-- General styling for context boxes (editor)
content_box = {
  background:
    color: deep_dark_blue

  border:
    radius: 5
    color: deep_dark_blue

  header:
    background: color: deep_dark_blue
    color: white
    padding: 4
    border_bottom:
      width: 0.5
      color: dark_blue_off

  footer:
    background: color: deep_dark_blue
    color: white
    padding: 4

}

return {
  window:
    outer_padding: 6
    background:
      image: theme_file('circle.png')

    status:
      font: bold: true
      color: blue

      info: color: white
      warning: color: yellow
      error: color: light_red

  :content_box

  popup: {
    background:
      color: deep_dark_blue
    border:
      color: dark_blue_off
      width: 1.5
  }

  editor: delegate_to content_box, {
    scrollbars:
      slider:
        color: keyword
        alpha: 0.8

    background: color: dark_blue
    indicators:
      default:
        color: yellow

    header:
      background:
        gradient:
          type: 'linear'
          direction: 'vertical'
          stops: { deep_dark_blue, deep_dark_blue, deep_dark_blue, dark_blue}
      padding_bottom: 10
      border_bottom: width: 0

    footer:
      background:
        gradient:
          type: 'linear'
          direction: 'vertical'
          stops: { dark_blue, deep_dark_blue, deep_dark_blue}
      padding_top: 10

    current_line:
      background: current

    gutter:
      color: dark_blue_off
      background:
        color: dark_blue
  }

  flairs:
    indentation_guide_1:
      type: flair.PIPE,
      foreground: yellow,
      foreground_alpha: 0.3
      line_width: 1
      line_type: 'solid'

    indentation_guide_2:
      type: flair.PIPE,
      foreground: yellow,
      foreground_alpha: 0.2
      line_width: 1
      line_type: 'solid'

    indentation_guide_3:
      type: flair.PIPE,
      foreground: yellow,
      foreground_alpha: 0.1
      line_width: 1
      line_type: 'solid'

    indentation_guide:
      type: flair.PIPE,
      foreground: yellow,
      foreground_alpha: 0.1
      line_width: 1
      line_type: 'solid'

    edge_line:
      type: flair.PIPE,
      foreground: white,
      foreground_alpha: 0.2,
      line_type: 'solid'
      line_width: 0.5

    search:
      type: highlight.ROUNDED_RECTANGLE
      foreground: white
      background: yellow
      text_color: dark_blue
      height: 'text'

    search_secondary:
      line_width: 1
      type: highlight.ROUNDED_RECTANGLE
      background: yellow
      background_alpha: 0.4
      text_color: light_grey
      height: 'text'

    replace_strikeout:
      type: highlight.ROUNDED_RECTANGLE
      foreground: white
      background: red
      text_color: lightgray
      background_alpha: 0.7
      height: 'text'

    brace_highlight:
      type: highlight.ROUNDED_RECTANGLE
      text_color: background
      background: yellow
      height: 'text'

    brace_highlight_secondary:
      type: highlight.RECTANGLE
      foreground: orange
      line_width: 1
      height: 'text'

    list_selection:
      type: highlight.ROUNDED_RECTANGLE
      background: white
      background_alpha: 0.1

    list_highlight:
      type: highlight.UNDERLINE
      text_color: yellow
      line_width: 2
      foreground: yellow

    cursor:
      type: highlight.RECTANGLE
      background: white
      width: 2
      height: 'text'

    block_cursor:
      type: highlight.RECTANGLE,
      background: white
      text_color: background
      height: 'text',
      min_width: 'letter'

    selection:
      type: highlight.ROUNDED_RECTANGLE
      background: selection
      background_alpha: 0.3
      min_width: 'letter'

  styles:
    default:
      color: light_grey

    red: color: red
    green: color: green
    yellow: color: yellow
    blue: color: blue
    magenta: color: magenta
    cyan: color: cyan

    comment:
      color: grey
      font: italic: true

    variable: color: yellow

    label:
      color: orange
      font: italic: true

    key:
      color: key

    char: color: green
    wrap_indicator: 'blue'

    fdecl:
      color: orange
      font:
        bold: true

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

    definition: color: yellow
    function: color: light_grey

    number:
      color: number
      font: bold: true

    operator:
      color: operator
      font: bold: true

    preproc:
      color: yellow
      font: italic: true

    special:
      color: special
      font: bold: true, italic: true

    tag: color: purple

    type: color: class_name

    member:
      color: light_grey
      font: bold: true

    info: color: light_grey
    constant: color: orange
    string: color: string

    regex:
      color: green

    embedded:
      background: white
      background_alpha: 0.1

    css_unit:
      color: green
      font: italic: true

    -- Markup and visual styles

    error:
      font:
        bold: true
      color: red

    warning:
      font: italic: true
      color: orange

    h1:
      color: yellow
      font:
        bold: true
        size: 'xx-large'

    h2:
      color: white
      color: yellow
      font: size: 'x-large'

    h3:
      color: yellow

    emphasis:
      font:
        bold: true
        italic: true

    strong: font: italic: true

    link_label:
      color: orange
      underline: true

    link_url:
      color: grey
      font: italic: true

    table:
      underline: true

    addition: color: green
    deletion: color: red
    change: color: yellow
  }
