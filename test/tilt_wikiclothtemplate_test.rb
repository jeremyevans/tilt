require_relative 'test_helper'

checked_describe 'tilt/wikicloth' do
  include IgnoreVerboseWarnings

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
