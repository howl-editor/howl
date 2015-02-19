-- Copyright 2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

flair = require 'aullar.flair'

describe 'flair', ->
  after_each -> flair.clear!

  describe 'define(name, opts)', ->
    it 'defines a flair with the given name, type and options', ->
      flair.define 'test', type: flair.RECTANGLE, foreground: '#112233'
      f = flair.get 'test'
      assert.equals flair.RECTANGLE, f.type
      assert.equals '#112233', f.foreground

  describe 'define_default(name, type, opts)', ->
    describe 'when no flair with <name> is defined', ->
      it 'defines the flair with the given name, type and options', ->
        flair.define_default 'test', type: flair.RECTANGLE, foreground: '#112233'
        f = flair.get 'test'
        assert.equals flair.RECTANGLE, f.type
        assert.equals '#112233', f.foreground

    describe 'when a flair with <name> is already defined', ->
      it 'does not change the existing definition', ->
        flair.define 'test', type: flair.RECTANGLE, foreground: '#112233'
        flair.define_default 'test', type: flair.SANDWICH, foreground: '#445566'
        f = flair.get 'test'
        assert.equals flair.RECTANGLE, f.type
        assert.equals '#112233', f.foreground
