import config from lunar

completion_options = { 'manual', 'auto', 'always' }

config.define {
  name: 'complete'
  description: 'Controls the operation of auto-completion'
  default: 'auto'
  validate: (value) ->
    alts = { name, true for name in *completion_options }
    alts[value]
  options: completion_options
}
