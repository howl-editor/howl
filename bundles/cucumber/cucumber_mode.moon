-- Copyright 2013 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

import style from howl.ui

style.define_default 'gherkin_step', 'symbol'
style.define_default 'gherkin_placeholder', 'preproc'
style.define_default 'gherkin_description', 'string'

is_header = (line) ->
  line\umatch r'^\\s{0,2}\\S+.*:'

{
  lexer: bundle_load('cucumber_lexer')

  indentation: {
    more_after: { ':' }
  }

  auto_pairs: {
      '(': ')'
      '(': ')'
      '"': '"'
      "'": "'"
    }

  structure: (editor) =>
    [l for l in *editor.buffer.lines when is_header l]
}
