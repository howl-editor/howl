module SitemapHelpers
  def howl_specs
    grouped(sitemap.where(:tags.include => 'spec').all)
  end

  def howl_api_docs
    grouped(sitemap.resources.select { |r| r.url.start_with? '/doc/api' })
  end

  def sliced_for_columns(nr_cols, packages)
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
      File.dirname(doc.url).tr('/', '.').gsub(/.doc.\w+/, 'howl')
    end
  end
end
