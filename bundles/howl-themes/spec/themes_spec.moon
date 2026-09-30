{:bundle, :config} = howl
{:theme} = howl.ui

describe 'howl-themes', ->
  local names, orig_theme

  setup ->
    orig_theme = config.theme
    all_before = {name, true for name in pairs theme.all}
    bundle.load_by_name 'howl-themes'
    names = [name for name in pairs theme.all when not all_before[name]]

  teardown ->
    config.theme = orig_theme
    bundle.unload 'howl-themes'

  it 'registers the bundled themes', ->
    assert.is_true #names > 0

  it 'has themes that apply without errors', ->
    for name in *names
      log.clear!
      config.theme = name
      assert.is_nil log.last_error, "#{name}: #{log.last_error and log.last_error.message}"
