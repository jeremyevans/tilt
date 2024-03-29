require_relative 'test_helper'

checked_describe 'tilt/markaby' do
  def before
    @block = lambda do |t|
      File.read(File.dirname(__FILE__) + "/#{t.file}")
    end
  end

  it "should be able to render a markaby template with static html" do
    tilt = Tilt::MarkabyTemplate.new("test/markaby/markaby.mab", &@block)
    assert_equal "hello from markaby!", tilt.render
  end

  it "should use the contents of the template" do
    tilt = ::Tilt::MarkabyTemplate.new("test/markaby/markaby_other_static.mab", &@block)
    assert_equal "_why?", tilt.render
  end

  it "should render from a string (given as data)" do
    tilt = ::Tilt::MarkabyTemplate.new { "html do; end" }
    assert_equal "<html></html>", tilt.render
  end

  it "can be rendered more than once" do
    tilt = ::Tilt::MarkabyTemplate.new { "html do; end" }
    3.times { assert_equal "<html></html>", tilt.render }
  end

  it "should evaluate a template file in the scope given" do
    scope = Object.new
    def scope.foo
      "bar"
    end

    tilt = ::Tilt::MarkabyTemplate.new("test/markaby/scope.mab", &@block)
    assert_equal "<li>bar</li>", tilt.render(scope)
  end

  it "should pass locals to the template" do
    tilt = ::Tilt::MarkabyTemplate.new("test/markaby/locals.mab", &@block)
    assert_equal "<li>bar</li>", tilt.render(Object.new, { :foo => "bar" })
  end

  it "should yield to the block given" do
    tilt = ::Tilt::MarkabyTemplate.new("test/markaby/yielding.mab", &@block)

    output = tilt.render(Object.new, {}) do
      text("Joe")
    end

    assert_equal "Hey Joe", output
  end

  it "should be able to render two templates in a row" do
    tilt = ::Tilt::MarkabyTemplate.new("test/markaby/render_twice.mab", &@block)

    assert_equal "foo", tilt.render
    assert_equal "foo", tilt.render
  end

  it "should retrieve a Tilt::MarkabyTemplate when calling Tilt['hello.mab']" do
    assert_equal Tilt::MarkabyTemplate, ::Tilt['test/markaby/markaby.mab']
  end

  it "should return a new instance of the implementation class (when calling Tilt.new)" do
    assert ::Tilt.new(File.dirname(__FILE__) + "/markaby/markaby.mab").kind_of?(Tilt::MarkabyTemplate)
  end

  it "should be able to evaluate block style templates" do
    tilt = Tilt::MarkabyTemplate.new { |t| lambda { h1 "Hello World!" }}
    assert_equal "<h1>Hello World!</h1>", tilt.render
  end

  it "should pass locals to block style templates" do
    tilt = Tilt::MarkabyTemplate.new { |t| lambda { h1 "Hello #{name}!" }}
    assert_equal "<h1>Hello _why!</h1>", tilt.render(nil, :name => "_why")
  end
end
