-- Copyright 2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

{:janitor, :config, :app} = howl
{:time} = os

cleanup_min_buffers_open = config.cleanup_min_buffers_open
cleanup_close_buffers_after = config.cleanup_close_buffers_after

close_buffers = ->
  for b in *app.buffers
    app\close_buffer b, true

describe 'janitor', ->
  local existing_buffer

  setup ->
    config.autoclose_single_buffer = false
    app.editor = nil

  before_each ->
    close_buffers!
    existing_buffer = app.buffers[1]

  after_each ->
    config.cleanup_min_buffers_open = cleanup_min_buffers_open
    config.cleanup_close_buffers_after = cleanup_close_buffers_after
    close_buffers!

  buffers = ->
    return app.buffers unless existing_buffer
    [b for b in *app.buffers when b != existing_buffer]

  describe 'clean_up_buffers', ->
    local now, one_hour_ago

    before_each ->
      now = time!
      one_hour_ago = now - (60 * 60)

    it 'never closes modified buffers', ->
      config.cleanup_min_buffers_open = 0
      config.cleanup_close_buffers_after = 0
      b = app\new_buffer!
      b.last_shown = one_hour_ago - 60
      b.modified = true
      janitor.clean_up_buffers!
      assert.equals 1, #buffers!

    it 'does not leave less than <cleanup_min_buffers_open> buffers', ->
      config.cleanup_min_buffers_open = 2
      config.cleanup_close_buffers_after = 0
      for _ = 1, 2
        b = app\new_buffer!
        b.last_shown = one_hour_ago - 60

      janitor.clean_up_buffers!
      assert.equals 2, #app.buffers

    it 'closes buffers who has not been shown recently enough', ->
      for i = 1, 2
        b = app\new_buffer!
        b.title = 'keep'
        b.last_shown = one_hour_ago + (i * 60)

      for i = 1, 2
        b = app\new_buffer!
        b.last_shown = one_hour_ago - (60 * i)

      config.cleanup_min_buffers_open = 2
      config.cleanup_close_buffers_after = 1
      janitor.clean_up_buffers!

      assert.equals 2, #buffers!

      for b in *buffers!
        assert.match b.title, 'keep'

    it 'neves closes buffers viewed more recently than the limit', ->
      for i = 1, 4
        b = app\new_buffer!
        b.title = 'keep'
        b.last_shown = one_hour_ago + (i * 60)

      config.cleanup_min_buffers_open = 2
      config.cleanup_close_buffers_after = 1
      janitor.clean_up_buffers!

      assert.equals 4, #buffers!

    it 'closes buffers in a least-recently-shown order', ->
      b = app\new_buffer!
      b.title = 'two-hour-old'
      b.last_shown = one_hour_ago - 60 * 60

      b = app\new_buffer!
      b.title = '15-min-old'
      b.last_shown = now - 60 * 15

      b = app\new_buffer!
      b.title = 'over-one-hour-old'
      b.last_shown = one_hour_ago - 60

      config.cleanup_min_buffers_open = 1
      config.cleanup_close_buffers_after = 1
      janitor.clean_up_buffers!

      assert.same {'15-min-old'}, [_b.title for _b in *buffers!]

