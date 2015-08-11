#! /usr/bin/env ruby
#
# Scrapes css-infos.net for CSS property documentation
#
# Copyright 2013-2015 The Howl Developers
# License: MIT (see LICENSE.md at the top-level directory of the distribution)

require 'open-uri'
require 'json'

site = 'http://css-infos.net'
start_pages = [ '', '/properties/webkit']
target = 'properties'
Dir.mkdir target unless Dir.exist? target

start_pages.map {|p| "#{site}/#{p}" }.each do |page|
  open(page) do |f|
    content = f.read
    properties = content.scan(/class="property"[^>]+>([^<]+)/).flatten
    puts "Scraping #{properties.size} properties from #{page}.."
    properties.each do |name|
      source = "#{site}/property/#{name}/json"
      dest = "#{target}/#{name}.json"
      puts "#{name} -> #{dest}.."
      open(source) do |f|
        info = f.read
        data = JSON.pretty_generate(JSON.parse(info))
        IO.write(dest, data)
      end
      sleep 1
    end
  end
end
