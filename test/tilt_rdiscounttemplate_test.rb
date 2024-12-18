require_relative 'test_helper'

checked_describe 'tilt/rdiscount' do
  it "registered above Kramdown" do
    %w[md mkd markdown].each do |ext|
      lazy = Tilt.lazy_map[ext]
      rdis_idx = lazy.index { |klass, file| klass == 'Tilt::RDiscountTemplate' }
      kd_idx = lazy.index { |klass, file| klass == 'Tilt::KramdownTemplate' }
      assert rdis_idx < kd_idx,
        "#{rdis_idx} should be lower than #{kd_idx}"
    end
  end

  it "preparing and evaluating templates on #render" do
    template = Tilt::RDiscountTemplate.new { |t| "# Hello World!" }
    3.times { assert_equal "<h1>Hello World!</h1>\n", template.render }
  end

  it "smartypants when :smart is set" do
    template = Tilt::RDiscountTemplate.new(:smart => true) { |t|
      "OKAY -- 'Smarty Pants'" }
    assert_equal "<p>OKAY &ndash; &lsquo;Smarty Pants&rsquo;</p>\n",
      template.render
  end

  it "stripping HTML when :filter_html is set" do
    template = Tilt::RDiscountTemplate.new(:filter_html => true) { |t|
      "HELLO <blink>WORLD</blink>" }
    assert_equal "<p>HELLO &lt;blink>WORLD&lt;/blink></p>\n", template.render
  end

  it "sets allows_script metadata set to false" do
    assert_equal false, Tilt::RDiscountTemplate.new { |t| "# Hello World!" }.metadata[:allows_script]
  end
end
