require_relative 'test_helper'

checked_describe 'tilt/redcloth' do
  it "is registered for '.textile' files" do
    assert_equal Tilt::RedClothTemplate, Tilt['test.textile']
  end

  it "compiles and evaluates the template on #render" do
    template = Tilt::RedClothTemplate.new { |t| "h1. Hello World!" }
    assert_equal "<h1>Hello World!</h1>", template.render
  end

  it "can be rendered more than once" do
    template = Tilt::RedClothTemplate.new { |t| "h1. Hello World!" }
    3.times { assert_equal "<h1>Hello World!</h1>", template.render }
  end

  it "ignores unknown options" do
    template = Tilt::RedClothTemplate.new(:foo => "bar") { |t| "h1. Hello World!" }
    3.times { assert_equal "<h1>Hello World!</h1>", template.render }
  end

  it "passes in RedCloth options" do
    template = Tilt::RedClothTemplate.new { |t| "Hard breaks are\ninserted by default." }
    assert_equal "<p>Hard breaks are<br />\ninserted by default.</p>", template.render
    template = Tilt::RedClothTemplate.new(:hard_breaks => false) { |t| "But they can be\nturned off." }
    assert_equal "<p>But they can be\nturned off.</p>", template.render
  end

  it "sets allows_script metadata set to false" do
    assert_equal false, Tilt::RedClothTemplate.new { |t| "h1. Hello World!" }.metadata[:allows_script]
  end
end
