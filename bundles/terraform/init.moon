-- Terraform language support for Howl Editor
-- License: MIT

mode_reg =
  name: 'terraform'
  extensions: { 'tf', 'tfvars' }
  create: -> bundle_load('terraform_mode')!

howl.mode.register mode_reg

unload = -> howl.mode.unregister 'terraform'

return {
  info:
    author: 'Howl Editor Contributors',
    description: 'Terraform/HCL language support',
    license: 'MIT',
  :unload
}
