# (C) 2014 Nils Nordman <nino at nordman.org>, MIT license.

# Work-around for bug in middleman for relative links for blogs

class BlogAbsoluteLinks
  def initialize(app)
    @app = app
  end

  def call(env)
    status, headers, response = @app.call(env)
    return [status, headers, response] unless status == 200 and env['PATH_INFO'] =~ %r|^/blog/.+/.+\.html$|
    content = content response
    content = content.gsub %r|<a href="(\.\./)+|, '<a href="/'
    return [status, headers, [content]]
  end

  private

  def content(response)
    response.enum_for(:each).inject('', &:+)
  end

end
