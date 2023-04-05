require_relative 'test_helper'

begin
  require 'tilt/kramdown'
rescue LoadError => e
  warn "Tilt::KramdownTemplate (disabled): #{e.message}"
else
  describe 'tilt/kramdown' do
    it "preparing and evaluating templates on #render" do
      template = Tilt::KramdownTemplate.new { |t| "# Hello World!" }
      3.times { assert_equal '<h1 id="hello-world">Hello World!</h1>', template.render.strip }
    end

    it "sets allows_script metadata set to false" do
      assert_equal false, Tilt::KramdownTemplate.new { |t| "# Hello World!" }.metadata[:allows_script]
    end
  end
end
