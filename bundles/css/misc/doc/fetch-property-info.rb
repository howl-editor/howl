#! /usr/bin/env ruby
#
# Scrapes css-infos.net for CSS property documentation
# (C) 2013 Nils Nordman <nino at nordman.org>, MIT license.

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
