require_relative 'test_helper'

begin
  require 'nokogiri'
rescue LoadError
  warn "Markdown tests need Nokogiri"
else
_MarkdownTests = Module.new do
  extend Minitest::Spec::DSL

  def self.included(mod)
    class << mod
      def template(t = nil)
        t.nil? ? @template : @template = t
      end
    end
  end

  def render(text, options = {})
    self.class.template.new(options) { text }.render
  end

  def normalize(html)
    Nokogiri::HTML.fragment(html).to_s.strip
  end

  def nrender(text, options = {})
    html = render(text, options)
    html.encode!("UTF-8")
    normalize(html)
  end

  it "should not escape html by default" do
    html = nrender "Hello <b>World</b>"
    assert_equal "<p>Hello <b>World</b></p>", html
  end

  it "should not escape html for :escape_html => false" do
    html = nrender "Hello <b>World</b>", :escape_html => false
    assert_equal "<p>Hello <b>World</b></p>", html
  end

  it "should escape html for :escape_html => true" do
    html = nrender "Hello <b>World</b>", :escape_html => true
    assert_equal "<p>Hello &lt;b&gt;World&lt;/b&gt;</p>", html
  end

  it "should not use smart quotes by default" do
    html = nrender 'Hello "World"'
    assert_equal '<p>Hello "World"</p>', html
  end

  it "should not use smart quotes if :smartypants => false" do
    html = nrender 'Hello "World"', :smartypants => false
    assert_equal '<p>Hello "World"</p>', html
  end

  it "should use smart quotes if :smartypants => true" do
    with_utf8_default_encoding do
      html = nrender 'Hello "World"', :smartypants => true
      assert_equal '<p>Hello “World”</p>', html
    end
  end

  it "should not use smartypants by default" do
    html = nrender "Hello ``World'' -- This is --- a it ..."
    assert_equal "<p>Hello ``World'' -- This is --- a it ...</p>", html
  end

  it "should not use smartypants if :smartypants => false" do
    html = nrender "Hello ``World'' -- This is --- a it ...", :smartypants => false
    assert_equal "<p>Hello ``World'' -- This is --- a it ...</p>", html
  end
end

markdown_describe = ->(lib, constant, &block) do
  begin
    require lib
  rescue LoadError
    # do nothing, main tests for the lib already warn
  else
    describe("#{lib} (markdown)") do
      include _MarkdownTests
      template Tilt.const_get(constant)
      instance_exec(&block) if block
    end
  end
end


markdown_describe.call 'tilt/rdiscount', :RDiscountTemplate do
  it "should use smartypants if :smartypants => true" do
    html = nrender "Hello ``World'' -- This is --- a it ...", :smartypants => true
    assert_equal "<p>Hello “World” – This is — a it …</p>", html
  end
end

markdown_describe.call 'tilt/redcarpet', :RedcarpetTemplate do
  it "should use smartypants if :smartypants => true" do
    # Various versions of Redcarpet support various versions of Smart pants.
    html = nrender "Hello ``World'' -- This is --- a it ...", :smartypants => true
    assert_match %r!<p>Hello “World(''|”) – This is — a it …<\/p>!, html
  end

  it "should support :no_links option" do
    html = nrender "Hello [World](http://example.com)", :smartypants => true, :no_links => true
    assert_equal "<p>Hello [World](http://example.com)</p>", html
  end

  it "should support fenced code blocks with lang" do
    code = <<-COD.gsub(/^\s+/,"")
    ```ruby
    puts "hello world"
    ```
    COD

    html = nrender code, :fenced_code_blocks => true
    assert_equal %Q{<pre><code class="ruby">puts "hello world"\n</code></pre>}, html
  end
end

markdown_describe.call 'tilt/kramdown', :KramdownTemplate do
  skip_tests = [
    ':escape_html => true',
    'smartypants by default',
    'smartypants if :smartypants => false',
  ]
  instance_methods.grep(/#{Regexp.union(skip_tests)}\z/).each do |method|
    undef_method method
  end
end

markdown_describe.call 'tilt/pandoc', :PandocTemplate
end
