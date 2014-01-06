set :css_dir, 'stylesheets'
set :js_dir, 'javascripts'
set :images_dir, 'images'
set :relative_links, true

# Reload the browser automatically whenever files change
activate :livereload

activate :syntax

activate :deploy do |deploy|
  deploy.build_before = true
  deploy.clean = true
  deploy.method = :rsync
  deploy.host = "nf"
  deploy.port = 42000
  deploy.path = "www/howl.io"
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

# Build-specific configuration
configure :build do
  activate :relative_assets
end

helpers do
  def hdr_link(idx, title, path)
    "<h4>#{idx} <a href=\"#{path}\">#{title}</a></h4>"
  end
end
