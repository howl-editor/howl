require 'pathname'

set :css_dir, 'stylesheets'
set :js_dir, 'javascripts'
set :images_dir, 'images'
set :relative_links, true

ignore '*.bak'

# Reload the browser automatically whenever files change
activate :livereload

activate :syntax

activate :blog do |blog|
  blog.prefix = 'blog'
  blog.paginate = true

end

page "blog/*", :layout => :blog_layout

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

  def breadcrumbs
    component = Struct.new(:path, :title, :document_exists?)
    base = Pathname.new("/#{current_resource.destination_path}").parent

    components = []
    path = Pathname.new '/'
    parts = current_resource.path.split('/').reject { |p| p =~ /index\./ }
    parts.each do |part|
      path = path.join part
      resource = sitemap.find_resource_by_path(path.to_s) || sitemap.find_resource_by_path("#{path}/index.html")
      title = resource && resource.metadata[:page]['title']
      title ||= part =~ /([^.]+)/ && $1.capitalize
      components << component.new(path.relative_path_from(base), title, !!resource)
    end

    return '' if components.empty?

    crum = '<ol class="breadcrumb">'
    crum += '<li><a href="/">Home</a></li>'
    components[0..-2].each do |component|
      if component.document_exists?
        crum << "<li><a href='#{component.path}/'>#{component.title}</a></li>"
      else
        crum << "<li>#{component.title}</li>"
      end
    end
    crum += "<li>#{components[-1].title}</li>"
    crum + '</ol>'
  end
end
