module SitemapHelpers
  def howl_specs
    sitemap.where(:tags.include => 'spec').all.sort_by(&:url)
  end

  def howl_api_docs
    sitemap.resources.select { |r| r.url.start_with? '/doc/api' }.sort_by(&:url)
  end
end
