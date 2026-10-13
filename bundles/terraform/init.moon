-- Terraform language support for Howl Editor
-- License: MIT

mode_reg =
  name: 'terraform'
  extensions: { 'tf', 'tfvars' }
  create: -> bundle_load('terraform_mode')!

howl.mode.register mode_reg
howl.lsp.register_server name: 'terraform-ls', command: 'terraform-ls serve', modes: 'terraform'

unload = ->
  howl.mode.unregister 'terraform'
  howl.lsp.unregister_server 'terraform-ls'

return {
  info:
    author: 'Howl Editor Contributors',
    description: 'Terraform/HCL language support',
    license: 'MIT',
  :unload
}
