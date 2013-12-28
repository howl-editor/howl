require 'middleware/auto_format'

describe AutoFormat do

  def page(content, opts = {})
    <<-PAGE
    <html>
    <body class="#{Array(opts[:class]).join(' ')}">
      #{content}
    </body>
    </html>
    PAGE
  end

  def call(content, opts = {})
    app = double('app', call: [opts[:status] || 200, {}, [content]])
    autoformat = AutoFormat.new(app)
    autoformat.call(app)[2].join('')
  end

  context "when passed a non-manual page" do
    it "does nothing" do
      p = page '<h3 id="foo">foo (bar)</h3>'
      expect(call(p)).to eq(p)
    end
  end

  context "when passed a non-200 status page" do
    it "does nothing" do
      p = page '<h3 id="foo">foo (bar)</h3>', class: ['doc_api']
      expect(call(p, status: 304)).to eq(p)
    end
  end

  context "when passed a page with the body class doc_api" do
    it "extracts parameter lists from headers and anchors into their own elements" do
      p = page '<h3 id="foo-(bar)">foo (bar)</h3>', class: ['doc', 'doc_api', 'other']
      res = call p
      expect(res).to include('<h3 id="foo">foo <span class="arg-list">(bar)</span></h3>')
    end
  end
end
