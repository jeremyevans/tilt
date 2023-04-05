require_relative 'test_helper'

begin
  require 'tilt/wikicloth'
rescue LoadError => e
  warn "Tilt::WikiClothTemplate (disabled): #{e.message}"
else
  describe 'tilt/wikicloth' do
    it "is registered for '.mediawiki' files" do
      assert_equal Tilt::WikiClothTemplate, Tilt['test.mediawiki']
    end

    it "is registered for '.mw' files" do
      assert_equal Tilt::WikiClothTemplate, Tilt['test.mw']
    end

    it "is registered for '.wiki' files" do
      assert_equal Tilt::WikiClothTemplate, Tilt['test.wiki']
    end

    it "can be rendered more than once" do
      template = Tilt::WikiClothTemplate.new { |t| "= Hello World! =" }
      3.times { assert_match(/<h1>.*Hello World!.*<\/h1>/m, template.render) }
    end

    it "sets allows_script metadata set to false" do
      assert_equal false, Tilt::WikiClothTemplate.new { |t| "= Hello World! =" }.metadata[:allows_script]
    end
  end
end
