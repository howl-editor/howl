#! /usr/bin/env ruby
# Copyright 2014 Nils Nordman <nino at nordman.org>
# License: MIT (see LICENSE.md)

require 'pp'
require 'json'

active = false
root = {}
cur = nil

def add(fdef, root)
  fdef[:description].strip!
  parts = fdef[:f].split /[.:]/
  node = parts.inject(root) do |n, p|
    e = n[p]
    unless e
      e = {}
      n[p] = e
    end
    e
  end
  [:description, :signature].each {|f| node[f] = fdef[f]}
end

def add_keywords(root)
  [
    'and', 'break', 'do', 'elseif', 'else', 'end',
    'false', 'for', 'function',  'goto', 'if', 'in',
    'local', 'nil', 'not', 'or', 'repeat', 'return',
    'then', 'true', 'until', 'while'
  ].each do |kw|
    add({
      f: kw,
      signature: kw,
      description: 'Lua keyword',
    }, root)
  end
end

add_keywords root

ARGF.each do |line|
  unless active
    if line =~ /^\d+\.\d+.*Basic Functions/
      active = true
    else
      next
    end
  end

  if line =~ /^\d\s+.*Lua Standalone/
    add cur, root if cur
    active = false
  elsif line =~ /^### `([\w.:]+)/
    f = $1
    signature = line.sub('### ', '').gsub('`', '').chomp
    cur = {
      f: f,
      signature: signature,
      description: "# #{signature}"
  }
elsif cur and line =~ /^\* \*/
  add cur, root
  cur = nil
elsif cur
  cur[:description] += line
end
end

out = JSON.pretty_generate(root)
puts <<HDR
-- Lua API documentation, automatically compiled for Howl from
-- http://www.lua.org/manual/5.2/manual.html
--
-- by Roberto Ierusalimschy, Luiz Henrique de Figueiredo, Waldemar Celes
-- Copyright © 2011–2013 Lua.org, PUC-Rio. Freely available under the terms of the Lua license.
--
-- Copyright © 1994–2014 Lua.org, PUC-Rio.
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy of
-- this software and associated documentation files (the "Software"), to deal in
-- the Software without restriction, including without limitation the rights to
-- use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
-- the Software, and to permit persons to whom the Software is furnished to do so,
-- subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING -- BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND -- NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.
HDR
puts puts out.tr '[]', '{}'
