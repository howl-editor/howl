#! /usr/bin/env ruby
#
# Compiles the standalone CSS property JSON information into one .moon file.
# Fast and hacky way of getting it done.
# (C) 2013 Nils Nordman <nino at nordman.org>, MIT license.

require 'json'
require 'pp'
require 'sanitize'

def cleanup_html(s)
  return '' unless s
  s = s.gsub(%r|<a href="([^"]+)".+</a>|, "(\\1)")
  Sanitize.clean(s).strip
end

def invalid_property?(name)
  name =~ /[<(]/
end

def parse_values(values)
  h = {}
  values.each do |k,v|
    if v['values']
      v['values'].reject { |k, v| invalid_property?(k) }.map { |k,v| h[k] = cleanup_html(v) }
    elsif not invalid_property?(k)
      h[k] = cleanup_html(v['description'])
    end
  end
  h
 end

entries = Dir.glob('properties/*.json').inject({}) do |m, f|
  json = JSON.load(File.new(f))
  values = parse_values(json['values'] || {})
  entry = {
    'description' => cleanup_html(json['description']),
    'values' => values
  }
  name = File.basename(f, '.json')
  m[name] = entry

  if name =~ /-webkit-(.+)$/
    name = $1
    ['-moz-', '-ms-', '-o-'].each do |pfx|
      m["#{pfx}#{name}"] = entry
    end
  end

  m
end

entries = Hash[entries.sort_by { |k,v| k }]

out = JSON.pretty_generate(entries)
puts '-- CSS properties, automatically compiled from http://css-infos.net'
puts
puts out.tr '[]', '{}'
