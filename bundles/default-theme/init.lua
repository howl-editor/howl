local mod_name = ...
local theme_file = vilu.bundle.file_for(mod_name, 'default_theme.moon')

vilu.ui.theme.register('Default', theme_file)
