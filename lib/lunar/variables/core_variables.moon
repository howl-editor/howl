import config from lunar

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
