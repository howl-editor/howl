# Generates table of contents for api documents.
# Fast, non-parameterized and hacky way of getting it done.
# (C) 2013 Nils Nordman <nino at nordman.org>, MIT license.

class AutoTOC
  def initialize(app)
    @app = app
  end

  def call(env)
    status, headers, response = @app.call(env)
    response_body = ''
    response.each { |p| response_body += p }
    return [status, headers, response] unless is_api_page?(response_body)

    toc = generate_toc response_body
    response_body = response_body.sub('<h2', "#{toc}<h2")
    headers["Content-Length"] = response_body.length.to_s
    [status, headers, [response_body]]
  end

  def is_api_page?(content)
    ['<html>', 'dev_api'].all? { |t| content.include? t }
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
    return '' if hdrs.empty?

    hdrs.each_with_index do |hdr, idx|
      level, target_id, text = hdr
      if level == '2'
        toc += "</div>\n" unless idx.zero?
        toc += "<div class=\"toc-group\">\n"
        cls = text.downcase.gsub(' ', '_')
        toc += "<a href=\"##{target_id}\" class=\"toc-group-header #{cls}\">#{text}</a>\n"
      else
        toc += "<li class=\"\"><a href=\"##{target_id}\">#{text}</a></li>\n"
      end
    end
    toc += "</div>\n</div>\n</div>\n"
  end

end
