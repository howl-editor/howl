-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

styles = require 'aullar.styles'
config = require 'aullar.config'
{:cast} = require 'ffi'
{:SCALE} = require 'ljglibs.pango'

describe 'styles', ->

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

  context 'sub styling', ->
    it 'supports styles being composed of a base and an override', ->
      styles.define 'base', {
        background: '#112233'
        color: '#445566'
        font: {
          bold: true
        }
      }

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
