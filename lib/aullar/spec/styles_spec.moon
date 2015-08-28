-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

styles = require 'aullar.styles'
config = require 'aullar.config'
{:cast} = require 'ffi'
{:SCALE} = require 'ljglibs.pango'

describe 'styles', ->
  before_each ->
    styles.define 'default', {}

  describe 'define(name, def)', ->
    it 'defines the style', ->
      styles.define 'foo', strike_through: true
      def = styles.def_for 'foo'
      assert.same { name: 'foo', strike_through: true }, def

    it 'defines a style alias if <def> is a string', ->
      styles.define 'foo', strike_through: true
      styles.define 'bar', 'foo'
      def = styles.def_for 'bar'
      assert.same { name: 'foo', strike_through: true }, def

  describe 'define_default(name, definition)', ->
    it 'defines the style only if it is not already defined', ->
      styles.define_default 'preset', color: '#334455'
      assert.equal '#334455', styles.def_for('preset').color

      styles.define_default 'preset', color: '#667788'
      assert.equal '#334455', styles.def_for('preset').color

  describe 'font handling', ->
    it 'allows for proportional font size specifications', ->
      default = config.view_font_size
      size_for = (attr) ->
        attrs = styles.create_attributes attr
        cast('PangoAttrSize *', attrs[1]).size / SCALE

      assert.equals default - 1, size_for font: { size: 'small' }
      assert.equals default, size_for font: { size: 'medium' }
      assert.equals default + 1, size_for font: { size: 'large' }

  describe 'style stacking', ->
    it 'bases all styles upon the default style', ->
      styles.define 'default', color: '#112233', font: { bold: true }
      styles.define 'bar', {}
      def = styles.def_for 'bar'
      assert.equal '#112233', def.color
      assert.is_true def.font.bold

  context 'sub styling', ->
    before_each ->
      styles.define 'base', {
        background: '#112233'
        color: '#445566'
        font: {
          bold: true
        }
      }

    it 'supports styles being composed of a base and an override', ->
      styles.define 'override', {
        color: '#999999'
        font: {
          italic: true
        }
      }

      def = styles.def_for 'base:override'
      assert.is_not_nil def
      assert.equal '#112233', def.background
      assert.equal '#999999', def.color
      assert.is_true def.font.italic
      assert.is_true def.font.bold

    it 'allows aliases for the override', ->
      styles.define 'real_style', color: '#999999'
      styles.define 'test_alias', 'real_style'

      def = styles.def_for 'base:test_alias'
      assert.is_not_nil def
      assert.equal '#112233', def.background
      assert.equal '#999999', def.color
