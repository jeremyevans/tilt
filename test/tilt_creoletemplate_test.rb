require_relative 'test_helper'

begin
  require 'tilt/creole'
rescue LoadError => e
  warn "Tilt::CreoleTemplate (disabled): #{e.message}"
else
  describe 'tilt/creole' do
    it "is registered for '.creole' files" do
      assert_equal Tilt::CreoleTemplate, Tilt['test.creole']
    end

    it "compiles and evaluates the template on #render" do
      template = Tilt::CreoleTemplate.new { |t| "= Hello World!" }
      3.times { assert_equal "<h1>Hello World!</h1>", template.render }
    end

    it "supports :allowed_schemes, :extensions, :no_escape options" do
      template = Tilt::CreoleTemplate.new(:allowed_schemes=>['http'], :extensions=>true, :no_escape=>true) { |t| "[[/Test]]" }
      assert_equal "<p><a href=\"/Test\">/Test</a></p>", template.render
    end

    it "sets allows_script metadata set to false" do
      assert_equal false, Tilt::CreoleTemplate.new { |t| "= Hello World!" }.metadata[:allows_script]
    end
  end
end
