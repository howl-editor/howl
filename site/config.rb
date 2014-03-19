set :css_dir, 'stylesheets'
set :js_dir, 'javascripts'
set :images_dir, 'images'
set :relative_links, true

ignore '*.bak'

# Reload the browser automatically whenever files change
activate :livereload

activate :syntax

activate :s3_sync do |s3_sync|
  s3_sync.bucket = 'howl.io'
  s3_sync.region = 'eu-west-1'
  s3_sync.add_caching_policy :default, max_age: 60 * 30
end

require "redcarpet"
set :markdown_engine, :redcarpet
set :markdown, {
  fenced_code_blocks: true,
  smartypants: true,
  autolink: true,
  tables: true,
  with_toc_data: true,
  no_intra_emphasis: true,
  footnotes: true
}

require 'middleware/auto_format'
use AutoFormat

helpers do
  def hdr_link(idx, title, path)
    "<h4>#{idx} <a href=\"#{path}\">#{title}</a></h4>"
  end
end
