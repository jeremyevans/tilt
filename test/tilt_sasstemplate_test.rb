require_relative 'test_helper'

checked_describe 'tilt/sass' do
  it "is registered for '.sass' files" do
    assert_equal Tilt::SassTemplate, Tilt['test.sass']
  end

  it "sets allows_script metadata set to false" do
    assert_equal false, Tilt::SassTemplate.new{''}.metadata[:allows_script]
  end

  it "compiles and evaluates the template on #render" do
    template = Tilt::SassTemplate.new({ style: :compressed }) { |t| "#main\n  background-color: #0000f1" }
    3.times { assert_equal "#main{background-color:#0000f1}", template.render.chomp }
  end

  it "is registered for '.scss' files" do
    assert_equal Tilt::ScssTemplate, Tilt['test.scss']
  end

  it "compiles and evaluates the template on #render" do
    template = Tilt::ScssTemplate.new({ style: :compressed }) { |t| "#main {\n  background-color: #0000f1;\n}" }
    3.times { assert_equal "#main{background-color:#0000f1}", template.render.chomp }
  end
end
