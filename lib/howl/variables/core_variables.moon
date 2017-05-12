-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import config from howl

config.define {
  name: 'complete'
  description: 'Controls the operation of auto-completion'
  default: 'auto'
  options: {
    { 'manual', 'Only complete when explicitly asked' }
    { 'auto', 'Complete whenever it is deemed appropriate' }
    { 'always', 'Alway start completion automatically' }
  }
}

config.define {
  name: 'word_pattern'
  description: 'A pattern determining what constitutes a "word" in a buffer'
  default: r'\\b[\\pL_][\\pL\\d_]*\\b'
}

config.define
  name: 'auto_format'
  description: 'Whether to automatically format code when possible'
  default: true
  type_of: 'boolean'

config.define
  name: 'preview_files'
  description: 'Whether to automatically preview the selected file or buffer'
  default: true
  type_of: 'boolean'
  scope: 'global'

config.define {
  name: 'inspectors_on_idle'
  description: 'List of on-idle inspectors to run for a buffer'
  type_of: 'string_list'
  default: {}
}

config.define {
  name: 'inspectors_on_save'
  description: 'List of on-save inspectors to run for a buffer'
  type_of: 'string_list'
  default: {}
}

config.define {
  name: 'auto_inspect'
  description: 'When to automatically inspect code for abberrations'
  default: 'idle'
  options: {
    { 'manual', 'Run all inspectors when explicitly asked' }
    { 'idle', 'Run on-idle inspectors on idle and on-save inspectors on save' }
    { 'save', 'Run all inspectors, but only on save' }
  }
}

config.define {
  name: 'display_inspections_delay'
  description: 'The delay before inspections are displayed at the current pos (ms, minimum 500ms)'
  type_of: 'number'
  default: 500
  scope: 'global'
  validate: (v) ->
    return false unless type(v) == 'number'
    v >= 500

}
