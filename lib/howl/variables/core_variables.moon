-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

{:config} = howl

config.define
  name: 'hidden_file_extensions'
  description: 'File extensions that determine which files should be hidden in file selection lists'
  scope: 'global'
  type_of: 'string_list'
  default: {'a', 'bc', 'git', 'hg', 'o', 'pyc', 'so', 'svn', 'cvs'}

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
  default: 'on'
  options: {
    { 'off', 'Run all inspectors only when explicitly asked to' }
    { 'on', 'Run on-idle inspectors on idle and on-save inspectors on save' }
    { 'save_only', 'Run all inspectors, but only on save' }
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

config.define {
  name: 'activities_popup_delay'
  description: 'The delay before a popup is displayed for a running activity (ms)'
  type_of: 'number'
  default: 700
  scope: 'global'
}

config.define {
  name: 'popup_menu_accept_key'
  description: 'What key should be used for accepting the current option of a popup menu?'
  default: 'enter'
  scope: 'global'
  options: {
    { 'enter', 'Pressing <ENTER> accepts the current option' }
    { 'tab', 'Pressing <TAB> accepts the current option' }
  }

}
