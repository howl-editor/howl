# Copyright 2014-2015 The Howl Developers
# License: MIT (see LICENSE.md at the top-level directory of the distribution)

# Work-around for bug in middleman for relative links for blogs
# Auto-linking of Github issues

class BlogAdjustments
  def initialize(app)
    @app = app
  end

  def call(env)
    status, headers, response = @app.call(env)
    return [status, headers, response] unless status == 200 and env['PATH_INFO'] =~ %r|^/blog/.+/.+\.html$|
    content = content response
    content = fix_absolute_links content
    content = auto_link_issues content
    return [status, headers, [content]]
  end

  private

  def fix_absolute_links(content)
    content.gsub %r|<a href="(\.\./)+|, '<a href="/'
  end

  def auto_link_issues(content)
    content.gsub %r|issue #(\d+)|, '<a href="https://github.com/howl-editor/howl/issues/\1">\0</a>'
  end

  def content(response)
    response.enum_for(:each).inject('', &:+)
  end

end
