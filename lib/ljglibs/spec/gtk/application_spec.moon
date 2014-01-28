gio = require 'ljglibs.gio'
Application = require 'ljglibs.gtk.application'

describe 'Application', ->
  it 'takes application id and flags as constructor arguments', ->
    app = Application 'my.App', gio.Application.HANDLES_OPEN
    assert.equal 'my.App', app.application_id
    assert.equal gio.Application.HANDLES_OPEN, app.flags

  it 'forwards methods to GApplication', ->
    app = Application 'my.App', Application.HANDLES_OPEN
    assert.is_true app\register!
