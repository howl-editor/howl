gio = require 'ljglibs.gio'
import Application from gio

describe 'Application', ->
  local app

  after_each -> app\quit!

  it 'takes application id and flags as constructor arguments', ->
    app = Application 'my.App', Application.HANDLES_OPEN
    assert.equal 'my.App', app.application_id
    assert.equal gio.Application.HANDLES_OPEN, app.flags

  describe 'register()', ->
    it 'returns true upon succesful registration', ->
      app = Application 'my.GApp', Application.HANDLES_OPEN
      assert.is_true app\register!

  describe 'run()', ->
    it 'accepts a table of strings as parameter', ->
      app = Application 'my.RunGApp'
      on_activate = spy.new ->
      app\connect 'activate', on_activate
      app\register!

      app\run {'foo'}

  describe '(signals)', ->
    it 'on_open is called with the files specified', ->
      app = Application 'my.OpenGApp', Application.HANDLES_OPEN
      app\on_open (cb_app, files) ->
        assert.equal app, cb_app
        assert.same { '/tmp.foo', '/bin/ls' }, [f.path for f in *files]

      app\register!
      app\run { 'howl', '/tmp.foo', '/bin/ls' }
