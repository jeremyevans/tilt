require_relative 'test_helper'

checked_describe 'tilt/rst-pandoc' do
  it "is registered for '.rst' files" do
    assert_equal Tilt::RstPandocTemplate, Tilt['test.rst']
  end

  it "compiles and evaluates the template on #render" do
    template = Tilt::RstPandocTemplate.new { |t| "Hello World!\n============" }
    assert_equal "<h1 id=\"hello-world\">Hello World!</h1>", template.render
  end

  it "can be rendered more than once" do
    template = Tilt::RstPandocTemplate.new { |t| "Hello World!\n============" }
    3.times do
      assert_equal "<h1 id=\"hello-world\">Hello World!</h1>", template.render
    end
  end

  it "supports :escape_html option" do
    template = Tilt::RstPandocTemplate.new(:escape_html => true) { |t| "HELLO <blink>WORLD</blink>" }
    assert_equal "<p>HELLO &lt;blink&gt;WORLD&lt;/blink&gt;</p>", template.render
  end

  it "sets allows_script metadata set to false" do
    assert_equal false, Tilt::RstPandocTemplate.new { |t| "Hello World!\n============" }.metadata[:allows_script]
  end
end
