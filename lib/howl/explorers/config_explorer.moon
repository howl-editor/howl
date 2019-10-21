-- Copyright 2019 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

{:config} = howl
{:StyledText, :markup} = howl.ui

append = table.insert

get_help = ->
  help = howl.ui.HelpContext!
  help\add_section
    heading: 'Steps'
    text: '1. Select a variable
2. Select the scope and layer for the variable
3. Select or type a value and press <keystroke>enter</>'
  help

stringify = (value, to_s) ->
  return to_s(value) if type(value) != 'table'
  [stringify o, to_s for o in *value]

get_options_for = (def) ->
  local options
  if def.options
    options = def.options
    options = options! if callable options

    table.sort options, (a, b) ->
      to_s = tostring or def.tostring
      a_str = stringify a, to_s
      b_str = stringify b, to_s
      return a_str < b_str if type(a_str) != 'table'
      return a_str[1] < b_str[1]
  options

class ConfigValue
  -- represents value at a specific scope and layer for a configuration value
  new: (@def, @config_proxy, @scope_alias, @description) =>
    -- The scope_alias is an optional short name for the scope and layer,
    -- to be displayed. E.g. for a project it could be 'project'.
    -- When not provided, the displayed text is the full scope followed by the
    -- layer in square brackets.
    -- The config_proxy is an instance of config.proxy
    unless @scope_alias
      layer_suffix = if @config_proxy.layer == 'default' then '' else "[#{@config_proxy.layer}]"
      @scope_alias = (@config_proxy.scope or '') .. layer_suffix

    options = get_options_for @def
    if options
      @options = {}
      for option in *options
        if type(option) == 'table'
          option = moon.copy option
          option.value = @to_s option[1]  -- the first item is the value
        else
          option = {option, value: @to_s option}
        append @options, option
    else
      @options = nil

  get_value: => @current_value_str!
  set_value: (value) => @_new_value = if value.is_blank then nil else value
  get_options: => @options

  commit: =>
    -- commit the currently set value to the config
    @config_proxy[@def.name] = @new_value!
    log.info ('"%s" is now set to "%s" for %s')\format @def.name, @new_value!, @scope_alias

  current_value: => @config_proxy[@def.name]
  new_value: => @_new_value
  current_value_str: => @to_s @current_value!
  new_value_str: => @to_s @new_value!
  to_s: (value) =>
    return '' if value == nil
    s = @def.tostring or tostring
    return s value

  display_title: => "Value for #{@def.name}"
  get_help: => get_help!

  display_row: => { @scope_alias, @current_value_str!, @description}
  display_path: => @def.name .. '@' .. @scope_alias .. '='
  preview: (text) =>
    current_value = @current_value!

    preview_value = (value) ->
      if type(value) == 'table'
        StyledText.for_table(value, {{style: 'string'}}) .. markup.howl "<comment>#{#value} items</>"
      elseif value == nil
        markup.howl '<comment>nil</>'
      else
        markup.howl "<string>#{value}</>"

    preview_text = markup.howl "<h1>#{@def.name} at #{@scope_alias}</>\n\n"
    long_description = "#{@def.description}\n#{@description}"
    preview_text ..= StyledText long_description, 'comment'
    preview_text ..= markup.howl '\n\n<keyword>Current value:\n</keyword>'
    preview_text ..= preview_value current_value

    if text
      preview_text ..= markup.howl '\n\n<keyword>New value:</>\n'
      if text.is_blank
        preview_text ..= markup.howl '<comment>nil</>'
      else
        new_value = if @def.convert then @def.convert(text) else text
        validate_ok, _ = pcall -> config.validate @def, new_value
        if validate_ok
          preview_text ..= preview_value new_value
        else
          preview_text ..= StyledText "Invalid value '#{new_value}' (#{@def.type_of} expected)", 'error'
    return {title: "About: #{@def.name}", text: preview_text}

configuration_values = (def, buffer) ->
  options = get_options_for def
  items = {}
  -- always include the global scope
  append items, ConfigValue(def, config, 'global', '')
  return items if def.scope == 'global' or not buffer

  -- always include the global scope with current mode layer
  mode_layer = buffer.mode.config_layer
  layer_config = config.proxy '', mode_layer
  mode_name = buffer.mode.name
  append items, ConfigValue(
    def, layer_config, "global[#{mode_layer}]",
    "For all buffers with mode #{mode_name}")

  if buffer.file
    -- include project scopes, when within a project
    project = howl.Project.for_file buffer.file
    if project
      append items, ConfigValue(
        def, project.config, 'project',
        "For all files under #{project.root.short_path}")

      project_layer_config = project.config.for_layer(mode_layer)
      append items, ConfigValue(
        def, project_layer_config, "project[#{mode_layer}]",
        "For all files under #{project.root.short_path} with mode #{mode_name}", options)

  append items, ConfigValue(
    def, buffer.config, 'buffer',
    "For #{buffer.title} only")

  return items

local ConfigExplorer

class ConfigVar
  -- lists values at different scopes for a single configuration variable
  new: (@def, @buffer) =>
    @scopes = configuration_values @def, @buffer
  display_row: => {@def.name, @def.description}
  display_title: => "Select scope for #{@def.name}"
  preview: =>
    preview_text = markup.howl "<h1>#{@def.name}</>\n\n"
    preview_text ..= StyledText @def.description, 'comment'
    s = @def.tostring or tostring
    preview_text ..= markup.howl "\n\n<keyword>Current value:</>"
    preview_text ..= markup.howl("\n<key>global</> ") .. StyledText s(config[@def.name]), 'string'
    if @def.scope != 'global'
      preview_text ..= markup.howl("\n<key>buffer</> ") .. StyledText s(@buffer.config[@def.name]), 'string'
    {text: preview_text, title: "About: #{@def.name}"}
  display_items: => @scopes
  display_columns: => {
    { style: 'key' }
    { style: 'string' }
    { style: 'comment' }
  }
  display_path: => @def.name .. '@'
  parse: (text) =>
    -- parses something like 'global=' into 'global', ''
    scope, remaining_text = text\match '([%w]+)=(.*)'

    -- jump to ConfigValue if scope text matches exactly
    if scope
      for scope_option in *@scopes
        scope_alias = scope_option.scope_alias
        if scope_alias == scope
          return jump_to: scope_option, text:remaining_text

    -- jump to ConfigValue if we only have one scope, e.g. 'global'
    if text.is_empty and #@scopes == 1
      -- jump_to_absolute means there is no ConfigVar explorer for this case
      -- pressing backspace goes back to a top level ConfigExplorer
      return jump_to_absolute: {ConfigExplorer(@buffer), @scopes[1]}

  get_help: => get_help!

get_vars = ->
  defs = [def for _, def in pairs config.definitions]
  table.sort defs, (a, b) -> a.name < b.name
  return defs

class ConfigExplorer
  -- lists all configuration variables available
  new: (@buffer) =>
  display_title: => 'Select configuration variable'
  display_columns: => {
    {'style': 'string'}, {'style': 'comment'}
  }
  display_items: =>
    [ConfigVar(def, @buffer) for def in *get_vars!]

  parse: (text) =>
    -- check if text contains '@' and parse 'var_name@scope'
    name, remaining_text = text\match '([%w_]+)@(.*)'
    unless name
    -- allow alternate syntax 'var_name='
      name = text\match '([%w_]+)=$'
      remaining_text = ''

    return unless name
    def = config.definitions[name]
    return unless def

    return jump_to: ConfigVar(def, @buffer), text: remaining_text

  get_help: => get_help!
