require 'pathname'
require 'yaml'

set :css_dir, 'stylesheets'
set :js_dir, 'javascripts'
set :images_dir, 'images'
set :relative_links, true

class << File
  alias_method :exists?, :exist?
end

ignore '*.bak'

# Reload the browser automatically whenever files change
activate :livereload

activate :syntax

activate :blog do |blog|
  blog.prefix = 'blog'
  blog.layout = 'blog_layout'
  blog.paginate = true
end

page "index.html", :layout => :base_layout
page "doc/manual/*", :layout => :manual_layout
page "versions/*", :layout => :manual_layout

activate :s3_sync do |s3_sync|
  auth_file = File.expand_path('~/.howl-auth')
  if File.exist?(auth_file)
    if File.stat(auth_file).world_readable?
      raise "'#{auth_file}' is world readable, please fix"
    end
    creds = YAML.load_file(auth_file)
    s3_sync.aws_access_key_id = creds['access_key']
    s3_sync.aws_secret_access_key = creds['secret_key']
  else
    $stderr.puts "WARN: #{auth_file} not present"
  end

  s3_sync.bucket = 'howl.io'
  s3_sync.region = 'eu-west-1'
  default_caching_policy max_age: 60 * 30
end

set :haml, { :format => :html5 }

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
require 'middleware/blog_adjustments'
use AutoFormat
use BlogAdjustments

helpers do
  def hdr_link(idx, title, path)
    "<h4><span class=\"hdr-idx\">#{idx}</span> <a href=\"#{path}\">#{title}</a></h4>"
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
      title = resource && (resource.metadata[:locals][:page_title] || resource.metadata[:page][:title])
      title ||= part =~ /([^.]+(?:\.\d+))/ && $1.capitalize
      components << component.new(path.relative_path_from(base), (title or part).capitalize, !!resource)
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

['steinom', 'monokai', 'solarized-light', 'tomorrow-night-blue', 'blueberry-blend', 'dracula'].each do |theme|
  proxy "/screenshots/#{theme}.html", "/templates/screenshots.html", {
    locals: {
      theme: theme,
      theme_name: theme.tr('-', ' ').capitalize,
      page_title: theme.tr('-', ' ').capitalize + ' theme'
    },
    ignore: true
  }
end
