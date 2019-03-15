module SitemapHelpers
  def howl_specs(version = nil)
    if version.present?
      prefix = "/versions/#{version}/doc/spec"
      grouped(sitemap.resources.select { |r| r.url.start_with? prefix })
    else
     grouped(sitemap.where(:tags.include => 'spec').all)
    end
  end

  def howl_api_docs(version = nil)
    prefix = version.present? ?
      "/versions/#{version}/doc/api" : '/doc/api'

    grouped(sitemap.resources.select { |r| r.url.start_with? prefix })
  end

  def howl_screenshots
    shots = sitemap.resources.select { |r| r.url =~ %r|/images/screenshots/.+/.+\.png$| }
    shots.sort_by(&:url).group_by do |doc|
      File.basename(File.dirname(doc.url))
    end
  end

  def howl_themes
    howl_screenshots.keys.map do |n|
      [n, n.tr('-', ' ').split(/\s+/).map(&:capitalize).join(' ')]
    end
  end

  def sliced_for_columns(nr_cols, packages)
    return if packages.empty?
    header_size = 3
    avg_length = packages.values.reduce(0) { |s, a| s + a.size } / nr_cols
    longest = packages.values.map(&:size).max
    goal_length = [avg_length, longest].max + header_size
    col = []
    length = 0

    packages.each do |package, docs|
      remaining = goal_length - length
      new_length = length + docs.size + header_size
      if new_length > goal_length and (new_length - goal_length) > remaining
        yield col
        col = []
        length = 0
      end
      col << { package: package, docs: docs }
      length += docs.size + header_size
    end
    yield col unless col.empty?
  end

  private

  def grouped(docs)
    docs.sort_by(&:url).group_by do |doc|
      File.dirname(doc.url).tr('/', '.').
        gsub(/\.versions\.\d+\.\d+/, '').
        gsub(/\.doc\.\w+/, 'howl')
    end
  end
end
