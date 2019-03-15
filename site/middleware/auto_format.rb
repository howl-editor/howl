# Copyright 2013-2015 The Howl Developers
# License: MIT (see LICENSE.md at the top-level directory of the distribution)

class AutoFormat
  def initialize(app)
    @app = app
  end

  def call(env)
    status, headers, response = @app.call(env)
    content = content response
    return [status, headers, response] unless status == 200 and content.include? '<html>'
    classes = classes content
    want_toc = (classes.include?(:doc) && !classes.include?(:doc_spec)) ||
      (classes.include?(:versions) && !env['PATH_INFO'].include?('/spec/'))
    content = generate_toc(content) if want_toc
    content = separate_arglists(content) if classes & [:doc_api, :doc_spec]
    headers["Content-Length"] = content.bytesize.to_s
    return [status, headers, [content]]
  end

  private

  def separate_arglists(content)
    content.gsub %r|(<h[23]\s+id=")([^"]+)([^>]+>)([^<]+)(</h[23]>)| do |hdr|
      open, anchor, close, middle, post = $1, $2, $3, $4, $5
      extracted = middle.gsub(/(\([^)]*\))/, '<span class="arg-list">\\1</span>')
      anchor = anchor.gsub(/-?\([^)]*\)/, '')
      open + anchor + close + extracted + post
    end
  end

  def generate_toc(content)
    title = 'INDEX'
    title = $1 if content =~ /<h1[^>]*>([^<]+)/

    toc = <<-HTML
    <div class="toc">
      <div class="toc-title">
        <span>#{title}</span>
      </div>
      <div class="toc-entries">
    HTML
    hdrs = content.scan(/<h([23])\s*id="([^"]+)[^>]+>([^<]+)/)
    return content if hdrs.empty?

    hdrs.each_with_index do |hdr, idx|
      level, target_id, text = hdr
      text = text[/^[^(]+/]
      target_id = target_id.gsub(/-?\([^)]*\)/, '')
      next if text.nil? or text.empty?
      if level == '2'
        toc += "</div>\n" unless idx.zero?
        toc += "<div class=\"toc-group\">\n"
        toc += "<a href=\"##{target_id}\" class=\"toc-group-header\">#{text}</a>\n"
      else
        toc += "<li class=\"\"><a href=\"##{target_id}\">#{text}</a></li>\n"
      end
    end
    toc += "</div>\n</div>\n</div>\n"
    content.sub('</h1>', "</h1>#{toc}")
  end

  def classes(content)
    if content =~ /<body\s+class=["']([^"']+)/
      $1.split(/\s+/).map(&:to_sym)
    else
      []
    end
  end

  def content(response)
    response.enum_for(:each).inject('', &:+)
  end

end
