gio = require 'ljglibs.gio'
Application = gio.Application

describe 'Application', ->
  it 'takes application id and flags as constructor arguments', ->
    app = Application 'my.App', Application.HANDLES_OPEN
    assert.equal 'my.App', app.application_id
    assert.equal gio.Application.HANDLES_OPEN, app.flags

  describe 'register()', ->
    it 'returns true upon succesful registration', ->
      app = Application 'my.GApp', Application.HANDLES_OPEN
      assert.is_true app\register!

    it 'returns true upon successful registration', ->
      app = Application 'my.GApp2', Application.HANDLES_OPEN
      assert.is_true app\register!

    it 'raises an error upon duplicate registration', ->
      app = Application 'my.GApp3', Application.HANDLES_OPEN
      assert.is_true app\register!

      app = Application 'my.GApp3', Application.HANDLES_OPEN
      assert.raises 'already exported', -> app\register!
