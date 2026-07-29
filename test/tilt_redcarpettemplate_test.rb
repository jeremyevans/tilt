require_relative 'test_helper'

checked_describe 'tilt/redcarpet' do
  it "works correctly with #extensions_for" do
    extensions = Tilt.default_mapping.extensions_for(Tilt::RedcarpetTemplate)
    assert_equal ['markdown', 'mkd', 'md'], extensions
  end

  it "registered above Kramdown" do
    %w[md mkd markdown].each do |ext|
      lazy = Tilt.lazy_map[ext]
      kd_idx = lazy.index { |klass, file| klass == 'Tilt::KramdownTemplate' }
      redc_idx = lazy.index { |klass, file| klass == 'Tilt::RedcarpetTemplate' }
      assert redc_idx < kd_idx,
        "#{redc_idx} should be lower than #{kd_idx}"
    end
  end

  it "registered above RDiscount" do
    %w[md mkd markdown].each do |ext|
      lazy = Tilt.lazy_map[ext]
      rdis_idx = lazy.index { |klass, file| klass == 'Tilt::RDiscountTemplate' }
      redc_idx = lazy.index { |klass, file| klass == 'Tilt::RedcarpetTemplate' }
      assert redc_idx < rdis_idx,
        "#{redc_idx} should be lower than #{rdis_idx}"
    end
  end

  it "sets allows_script metadata set to false" do
    assert_equal false, Tilt::RedcarpetTemplate.new{''}.metadata[:allows_script]
  end

  it "preparing and evaluating templates on #render" do
    template = Tilt::RedcarpetTemplate.new { |t| "# Hello World!" }
    3.times { assert_equal "<h1>Hello World!</h1>\n", template.render }
  end

  smarty_block = proc { |t| "OKAY -- 'Smarty Pants'" }
  smarty_regexp = %r!<p>OKAY &ndash; (&#39;|&lsquo;)Smarty Pants(&#39;|&rsquo;)<\/p>!

  it "smartypants when using :smart=>true" do
    template = Tilt::RedcarpetTemplate.new(:smart => true, &smarty_block)
    assert_match smarty_regexp, template.render
  end

  it "smartypants when using :smartypants=>true" do
    template = Tilt::RedcarpetTemplate.new(:smartypants => true, &smarty_block)
    assert_match smarty_regexp, template.render
  end

  it "smartypants when using :smartypants=>true, :renderer=>::Redcarpet::Render::HTML" do
    template = Tilt::RedcarpetTemplate.new(:smartypants => true, :renderer=>::Redcarpet::Render::HTML, &smarty_block)
    assert_match smarty_regexp, template.render
  end

  it "smartypants when using :smartypants=>true, :renderer=>::Redcarpet::Render::XHTML" do
    template = Tilt::RedcarpetTemplate.new(:smartypants => true, :renderer=>::Redcarpet::Render::XHTML, &smarty_block)
    assert_match smarty_regexp, template.render
  end

  it "smartypants when using :smartypants=>true, :renderer=>::Redcarpet::Render::Safe" do
    template = Tilt::RedcarpetTemplate.new(:smartypants => true, :renderer=>::Redcarpet::Render::Safe, &smarty_block)
    assert_match smarty_regexp, template.render
  end

  it "smartypants when using :smartypants=>true, :renderer=>::Redcarpet::Render::SmartyHTML" do
    template = Tilt::RedcarpetTemplate.new(:smartypants => true, :renderer=>::Redcarpet::Render::SmartyHTML, &smarty_block)
    assert_match smarty_regexp, template.render
  end

  it "smartypants with a :smartypants=>true, with :renderer instance" do
    template = Tilt::RedcarpetTemplate.new(:renderer => Redcarpet::Render::HTML.new(:hard_wrap => true), :smartypants => true, &smarty_block)
    assert_match smarty_regexp, template.render
  end
end
