---
title: Writing themes
---

# Writing themes

A Howl theme decides how the whole window looks: the colors and borders of the
window and the boxes within it, the styles used for the text in the editors, and
the _flairs_ drawn on top of the text, such as the cursor, the selection and
search highlights. A theme is a single CSS file, optionally accompanied by
images, that is registered with Howl by a bundle. In this page we'll go through
how to write one, how to check it for mistakes, and how to contribute it to
Howl.

Checking a theme for mistakes is done with a script from the Howl source, so
you'll want a checkout of the Howl repository at hand (see [Howl
development](dev-howl.html)).

## Getting started

The easiest way to get started is to copy one of the bundled themes and change
it from there. The bundled themes live in the `bundles/howl-themes` directory of
the Howl source, one directory per theme; the Monokai theme
(`bundles/howl-themes/monokai/monokai.css`) is the shortest one.

Themes are registered by bundles, so your theme needs a bundle of its own. Your
own bundles go in the `bundles` directory of your Howl user directory
(`~/.howl/` or `~/.config/howl/`, see [Init files](configuration.html#init-files)).
Create a directory for the bundle, named so that it doesn't clash with any other
bundle, and put your CSS file in it:

```
~/.howl/bundles/my-theme/
├── init.moon
└── my-theme.css
```

The bundle's `init.moon` registers the theme, and unregisters it again when the
bundle is unloaded:

```moonscript
{:theme} = howl.ui

theme.register 'My Theme', bundle_file('my-theme.css')

{
  info: {
    author: 'Your Name',
    description: 'My own theme',
    license: 'MIT',
  },
  unload: -> theme.unregister 'My Theme'
}
```

`bundle_file` resolves a path relative to the bundle's directory, and all
bundles must return the `info` fields and the `unload` function shown above.
Once you restart Howl, the theme shows up among the others when you set the
`theme` configuration variable (see [Configuring Howl](configuration.html)).

When you change the CSS file while the theme is in use, run the `bundle-reload`
command and select your bundle (`my_theme` in this case). This registers the
theme anew, which re-applies it with your changes. Setting the `theme` variable
to the theme already in use does not re-read the file.

## What's in a theme file

A theme file is [Gtk CSS](https://docs.gtk.org/gtk4/css-overview.html), which
styles the window and the widgets in it, plus a few extensions of Howl's own.
Howl processes these before handing the rest over to Gtk:

- **Variables**, declared in a `:root` block and used with `var(..)`. Howl
  expands them itself, so they work anywhere in the file, including in style and
  flair rules. A variable's value may refer to another variable.
- **`theme-url('file.png')`**, which refers to a file relative to the theme's
  CSS file. Use it for background images and the like.
- **Style rules**, `style.<name> { .. }`, which set the text styles used in the
  editors (see [Text styles](#text-styles)).
- **Flair rules**, `flair.<name> { .. }`, which set how the cursor, selection,
  highlights, etc. are drawn (see [Flairs](#flairs)).

Comments (`/* .. */`) can go anywhere. A small but complete theme looks like
this:

```css
:root {
  --background: #1d1f21;
  --foreground: #c5c8c6;
  --comment: #969896;
  --purple: #b294bb;
  --green: #b5bd68;
}

/* The window, and the boxes holding the editors and the command line */
window {
  background-color: var(--background);
}

.content-box {
  background-color: var(--background);
}

.gutter {
  color: var(--comment);
}

/* Text styles */
style.default {
  color: var(--foreground);
}

style.comment {
  color: var(--comment);
  font-style: italic;
}

style.keyword {
  color: var(--purple);
  font-weight: bold;
}

style.string { color: var(--green); }

/* Flairs */
flair.cursor {
  shape: pipe;
  border-color: var(--foreground);
  width: 2;
  height: text;
}

flair.selection {
  shape: rounded-rectangle;
  background-color: alpha(var(--purple), 0.3);
  minimum-width: letter;
}
```

Using a variable that isn't declared is an error that stops the whole theme
from being applied, while other mistakes only affect the rule they're in (see
[Checking a theme](#checking-a-theme)).

## Styling the window

Everything outside of the text itself is styled with ordinary Gtk CSS, using the
[properties Gtk supports](https://docs.gtk.org/gtk4/css-properties.html). These
are the selectors for Howl's parts of the window:

| Selector | What it is |
|---|---|
| `window` | The main window. `.main-window` is set on it as well |
| `window .container` | The area holding the views |
| `.content-box` | The box around an editor, the command line and the activity box. `.content-box-editor`, `.content-box-command_line` and `.content-box-activity` target one of them |
| `.content-box .header`, `.content-box .footer` | The indicator bars above and below an editor, and above the command line and activity box |
| `.indicator` | A single indicator in these bars. The indicator's id is set as a class too, so `.indicator.title`, `.indicator.position`, `.indicator.processes`, `.indicator.inspections` and `.indicator.vi` target one of them |
| `.gutter` | The line number gutter |
| `window .status` | The status messages. `.info`, `.warning` or `.error` is set along with it |
| `popover`, `popover contents` | Popups, such as the completion list |
| `scrollbar` | Scrollbars, e.g. `scrollbar range trough slider` |

The background of an editor is that of its `.content-box`. The font family and
size come from the `font` and `font_size` configuration variables, so themes
shouldn't set them for the window. Howl draws the line numbers in the gutter
itself, using the `color` of the `.gutter` rule.

## Text styles

A style rule sets the look of one kind of text, such as comments, keywords or
strings. The selector must be a single `style.<name>`: grouped selectors, such
as `style.keyword, style.string`, and any other combination are ignored. Dashes
and underscores in names mean the same thing, so `style.type-def` and
`style.type_def` are the same style. Several rules for the same style are
combined.

These properties are supported:

| Property | Values |
|---|---|
| `color` | The text color, as any CSS color. Must be opaque |
| `background-color` | Any CSS color, including transparent ones such as `#rrggbbaa` or `alpha(<color>, <0-1>)` |
| `font-style` | `italic` or `normal` |
| `font-weight` | `bold` or `normal` (not numbers) |
| `font-size` | A size in points (`12` or `12pt`), or one of `xx-small`, `x-small`, `small`, `smaller`, `medium`, `large`, `larger`, `x-large` and `xx-large`, relative to the editor's font size |
| `font-family` | A comma separated list of font families |
| `text-decoration` | `underline`, `line-through`, both, or `none` |

`style.default` is the base for all other styles: whatever a style doesn't set
is taken from `style.default`. A style that the theme doesn't define is shown
as the style it defaults to, if it has one, and as `style.default` otherwise. A
theme therefore only needs to define the styles it wants to differ.

Below are all the styles used by Howl and its bundled modes, along with the
style each one defaults to. The names are given as Howl's code uses them, with
underscores, but in a theme you can just as well write them with dashes, as the
bundled themes do (`style.type-def`). The bundled themes define all of the
[code](#code), [document](#documents) and [diff](#diffs) styles except
`identifier`, `symbol`, `parameter`, `global` and `header`, so they are a good
place to start from.

### Code

| Style | Used for | Defaults to |
|---|---|---|
| `comment` | Comments | |
| `keyword` | Keywords | |
| `string` | Strings | |
| `number` | Numbers | |
| `operator` | Operators and punctuation | |
| `identifier` | Other names, such as those of variables | |
| `constant` | Constants, such as upper case names | |
| `special` | Words and characters with a special meaning, such as `true`, `self` or string prefixes, depending on the language | |
| `type` | Type names | |
| `type_def` | Names of types being defined, such as in class declarations | `type` |
| `class` | Class names | |
| `fdecl` | Names of functions being defined | |
| `function` | Function names, such as those of built-in functions | |
| `key` | Keys, such as those in tables, hashes and objects | |
| `member` | Members, such as `@name` or `self.name` | |
| `variable` | Variables, in languages that mark them, such as `$name` in shell scripts | |
| `preproc` | Preprocessor directives, decorators and attributes | |
| `regex` | Regular expressions | `string` |
| `char` | Character literals | |
| `label` | Labels | |
| `tag` | Tags, such as those in XML | |
| `definition` | Definitions, such as Makefile targets | |
| `symbol` | Symbols, such as Ruby's `:name` | `key` |
| `parameter` | Parameters | `key` |
| `global` | Global variables, such as Ruby's `$name` | `member` |
| `error` | Invalid code | |
| `embedded` | Code embedded in other text, such as JavaScript in HTML or code in Markdown | |

Embedded code is shown with its own styles on top of `embedded`, so a
`background-color` set for `embedded` shows behind all embedded code.

### Documents

These are used for Markdown, mail and Cucumber files, and for the documentation
Howl shows in popups.

| Style | Used for | Defaults to |
|---|---|---|
| `h1`, `h2`, `h3` | Headings, and the subject in mail | |
| `emphasis` | Emphasized text: `*text*` and `_text_` in Markdown, `_text_` in mail | italic |
| `strong` | Strong text: `**text**` and `__text__` in Markdown, `*text*` in mail, and titles in Cucumber files | `bold` |
| `link_label` | Link texts | |
| `link_url` | Link addresses | |
| `table` | Tables in Cucumber files | |

### Diffs

| Style | Used for | Defaults to |
|---|---|---|
| `addition` | Added lines | |
| `deletion` | Removed lines | |
| `change` | Changed lines | |
| `header` | The `---` and `+++` lines naming the files | `comment` |

### The user interface

| Style | Used for | Defaults to |
|---|---|---|
| `default` | All text, and the base for the other styles | |
| `popup` | Popups, if it sets a `background-color` | `default` |
| `info`, `warning`, `error` | Messages, such as in notifications and the journal | |
| `prompt` | The command line prompt | `keyword` |
| `command_name` | Command names | `keyword` |
| `keystroke` | Key bindings, in help texts | `special` |
| `directory`, `filename` | Directories and files, when selecting files | `key`, `string` |
| `list_header` | Column headers in lists | grey, underlined |
| `wrap_indicator` | The marker shown where a line wraps | `comment` |
| `blob` | Lines too complex to style, such as minified code | `preproc` on top of `embedded` |
| `black`, `red`, `green`, `yellow`, `blue`, `magenta`, `cyan`, `white` | Plain colors. The colored output of external commands uses the `color` of these | Built-in colors |
| `bold` | Bold text | bold |

### Language specific styles

Some modes use styles of their own. All of them default to one of the styles
above, except ANTLR's `action`, which is plain text unless the theme defines it.

| Style | Language | Defaults to |
|---|---|---|
| `action` | ANTLR | |
| `builtInVariable`, `gawkBuiltInVariable`, `gawkKeyword`, `gawkNumber`, `gawkOperator`, `gawkRegex` | AWK | `constant`, `constant`, `keyword`, `number`, `operator`, `preproc` |
| `field` | AWK, BibTeX | `constant` |
| `entry` | BibTeX | `preproc` |
| `preprocessor` | C#, D, F#, Objective-C, Pike | `preproc` |
| `css_selector`, `css_property`, `css_unit`, `css_color`, `css_at`, `css_pseudo` | CSS | `keyword`, `key`, `type`, `string`, `preproc`, `class` |
| `gherkin_step`, `gherkin_placeholder`, `gherkin_description` | Cucumber | `symbol`, `preproc`, `string` |
| `annotation` | D, Java | `preproc` |
| `traits`, `versions` | D | `definition`, `constant` |
| `directive` | Erlang | `preproc` |
| `haml_element`, `haml_doctype`, `haml_id` | Haml | `keyword`, `special`, `constant` |
| `html_tag`, `html_attr`, `html_entity` | HTML | `keyword`, `key`, `preproc` |
| `jade_element`, `jade_id` | Jade | `keyword`, `constant` |
| `jsp_tag` | JSP | `embedded` |
| `environment`, `math`, `section` | LaTeX | `tag`, `function`, `class` |
| `mail_level_1`, `mail_level_2`, `mail_level_3`, `mail_level_4` | Mail, quotes by level | `green`, `blue`, `cyan`, `comment` |
| `mail_ref`, `mail_link` | Mail | `bold`, `link_url` |
| `target` | Makefiles | `definition` |
| `color` | Properties files | `number` |
| `attribute`, `element`, `namespace`, `entity`, `doctype`, `cdata` | XML | `key`, `type`, `special`, `special`, `comment`, `comment` |

## Flairs

Flairs are drawn on top of, or below, the text in the editors: the cursor, the
selection, the current line, search matches, and so on. Like styles, a flair
rule takes a single `flair.<name>` selector, and dashes and underscores in names
are the same. A flair defined by the theme replaces Howl's own definition
entirely, so a flair rule has to set everything the flair needs.

Every flair needs a `shape`, which is one of:

| Shape | Draws |
|---|---|
| `rectangle` | A box around the text, filled with `background-color` and outlined with `border-color` |
| `rounded-rectangle` | The same, with rounded corners |
| `sandwich` | A line above and below the text |
| `underline` | A line below the text |
| `wavy-underline` | A wavy line below the text |
| `pipe` | A vertical line at the start of the text |
| `strike-through` | A line through the text |

A flair without a valid shape is ignored. The other properties are:

| Property | Values |
|---|---|
| `border-color` | The color of the lines, or of the outline for rectangles. May be transparent |
| `background-color` | The fill color for rectangles. May be transparent |
| `color` | Redraws the text within the flair in this color. Must be opaque |
| `border-style` | `solid`, `dotted` or `dashed` |
| `border-radius` | The corner radius for `rounded-rectangle`, in pixels (`3` or `3px`) |
| `width` | The width of the lines, in pixels. This is not the width of the flair |
| `height` | The height in pixels, or `text` for the height of the text rather than the line |
| `minimum-width` | The minimum width in pixels, or `letter` for the width of a character. Lets a flair show where it covers no text, such as the cursor or the selection at the end of a line |

These are the flairs Howl uses:

| Flair | What it is |
|---|---|
| `cursor` | The cursor |
| `block-cursor` | The block cursor, used by the vi bundle's command mode |
| `inactive-cursor` | The cursor in editors that don't have the focus |
| `selection` | The selection |
| `selection-overlay` | Drawn over the selection where the text has a background color |
| `current-line` | The current line. It always spans the whole width of the editor, so it needs no `width` |
| `current-line-overlay` | Drawn on the current line over text with a background color |
| `indentation-guide` | The indentation guides. `indentation-guide-1`, `indentation-guide-2`, etc. override it for a given indentation level |
| `edge-line` | The line marking the edge column |
| `search`, `search-secondary` | The current search match, and the other matches |
| `replace-strikeout` | Text about to be replaced, when previewing a replacement |
| `brace-highlight` | The brace at the cursor, and its matching brace |
| `brace-highlight-secondary` | The brace just before the cursor, and its matching brace |
| `list-selection` | The selected item in lists |
| `list-highlight` | The characters matching what you typed, in lists |
| `list-visited` | Items already visited in list buffers, such as search results |
| `error`, `warning` | Errors and warnings reported by inspections |
| `stderr` | Error output of external commands |

Howl has built-in definitions for most of these. `brace-highlight`,
`brace-highlight-secondary`, `replace-strikeout` and `list-highlight` have none,
and are only visible if the theme defines them.

## Checking a theme

Mistakes in style and flair rules, such as an unknown property or an invalid
value, are logged as `Theme error:` when the theme is applied, as are the CSS
errors Gtk reports. The rest of the theme still applies. Within Howl, you can
see the messages with the `open-journal` command.

It's easier to use the `howl-check-themes` script in the `bin/` directory of the
Howl source, which applies themes without opening a window and lists the errors
for each theme. Give it a theme file:

```shell
[howl-dir] $ ./bin/howl-check-themes ~/.howl/bundles/my-theme/my-theme.css
FAIL  /home/you/.howl/bundles/my-theme/my-theme.css
      unsupported selector 'style.keyword, style.string', ignoring the rule: style and flair rules take a single name
      style.comment: text colors can't be transparent ('alpha(#969896, 0.5)')
      style.comment: invalid font-weight '700'
      flair.cursor: no valid shape, ignoring it
```

A theme without mistakes is listed as `ok`, and the script exits with a
non-zero status if any theme had errors. Gtk's errors are shown along with the
CSS surrounding them, where `<ERROR>` marks the spot. You can also give it the
name of a theme; with `--profile` it loads your user directory, so that themes
from your own bundles are included. Without arguments it checks all of the
bundled themes:

```shell
[howl-dir] $ ./bin/howl-check-themes --profile 'My Theme'
[howl-dir] $ ./bin/howl-check-themes
```

A theme without errors can of course still look wrong, so switch to it and see
for yourself.

## Contributing a theme to Howl

To add a theme to the themes bundled with Howl, add a directory for it under
`bundles/howl-themes/` and register it in the list of themes in
`bundles/howl-themes/init.moon`. Credits and copyright notes, e.g. for a theme
based on another, go in `bundles/howl-themes/README.md`. The bundle's spec
applies every bundled theme and fails on any error, so make sure it passes:

```shell
[howl-dir] $ ./bin/howl-spec bundles/howl-themes/spec
```

The website has screenshots of every bundled theme, taken by the
`screen-shooter` script. It's also a quick way to see a bundled theme in use;
this takes a screenshot with a few different views open, and writes it to
`/tmp/shots/my-theme/`:

```shell
[howl-dir] $ ./bin/screen-shooter /tmp/shots 'My Theme' multi-views
```

To add the theme to the site, generate all of its screenshots into
`site/source/images/screenshots` by leaving out the last argument, and add the
theme to the list of screenshot pages in `site/config.rb`.

---

.. Back to the [documentation index](../).
