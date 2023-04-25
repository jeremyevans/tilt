require_relative 'test_helper'

checked_describe 'tilt/slim' do
  self::MockError = Class.new(NameError)

  it "registered for '.slim' files" do
    assert_equal Tilt::SlimTemplate, Tilt['test.slim']
  end

  it "preparing and evaluating templates on #render" do
    template = Tilt::SlimTemplate.new { |t| "p Hello World!" }
    assert_equal "<p>Hello World!</p>", template.render
  end

  it "can be rendered more than once" do
    template = Tilt::SlimTemplate.new { |t| "p Hello World!" }
    3.times { assert_equal "<p>Hello World!</p>", template.render }
  end

  it "passing locals" do
    template = Tilt::SlimTemplate.new { "p= 'Hey ' + name + '!'" }
    assert_equal "<p>Hey Joe!</p>", template.render(Object.new, :name => 'Joe')
  end

  it 'evaluating in default/nil scope' do
    template = Tilt::SlimTemplate.new { |t| 'p Hey unknown!' }
    assert_equal "<p>Hey unknown!</p>", template.render
    assert_equal "<p>Hey unknown!</p>", template.render(nil)
  end

  it "evaluating in an object scope" do
    template = Tilt::SlimTemplate.new { "p= 'Hey ' + @name + '!'" }
    scope = Object.new
    scope.instance_variable_set :@name, 'Joe'
    assert_equal "<p>Hey Joe!</p>", template.render(scope)
  end

  it "passing a block for yield" do
    template = Tilt::SlimTemplate.new { "p= 'Hey ' + yield + '!'" }
    assert_equal "<p>Hey Joe!</p>", template.render { 'Joe' }
  end

  it "backtrace file and line reporting without locals" do
    data = File.read(__FILE__).split("\n__END__\n").last
    fail unless data.start_with? "html"
    template = Tilt::SlimTemplate.new('test.slim', 10) { data }
    begin
      template.render
      fail 'should have raised an exception'
    rescue => boom
      assert_kind_of NameError, boom
      line = boom.backtrace.grep(/\Atest\.slim:/).first
      assert line, "Backtrace didn't contain test.slim"
      _file, line, _meth = line.split(":")
      assert_equal '12', line
    end
  end

  it "backtrace file and line reporting with locals" do
    data = File.read(__FILE__).split("\n__END__\n").last
    fail unless data.start_with? "html"
    template = Tilt::SlimTemplate.new('test.slim') { data }
    begin
      template.render(self, :name => 'Joe', :foo => 'bar')
    rescue => boom
      assert_kind_of self.class::MockError, boom
      line = boom.backtrace.first
      file, line, _meth = line.split(":")
      assert_equal 'test.slim', file
      assert_equal '5', line
    end
  end

  _Scope = Class.new
  _Scope::MockError = Class.new(NameError)

  it "compiling template source to a method" do
    template = Tilt::SlimTemplate.new { |t| "Hello World!" }
    template.render(_Scope.new)
    method = template.send(:compiled_method, [])
    assert_kind_of UnboundMethod, method
  end

  it "passing locals" do
    template = Tilt::SlimTemplate.new { "p= 'Hey ' + name + '!'" }
    assert_equal "<p>Hey Joe!</p>", template.render(_Scope.new, :name => 'Joe')
  end

  it 'evaluating in default/nil scope' do
    template = Tilt::SlimTemplate.new { |t| 'p Hey unknown!' }
    assert_equal "<p>Hey unknown!</p>", template.render
    assert_equal "<p>Hey unknown!</p>", template.render(nil)
  end

  it "evaluating in an object scope" do
    template = Tilt::SlimTemplate.new { "p= 'Hey ' + @name + '!'" }
    scope = _Scope.new
    scope.instance_variable_set :@name, 'Joe'
    assert_equal "<p>Hey Joe!</p>", template.render(scope)
  end

  it "passing a block for yield" do
    template = Tilt::SlimTemplate.new { "p= 'Hey ' + yield + '!'" }
    assert_equal "<p>Hey Joe!</p>", template.render(_Scope.new) { 'Joe' }
  end

  it "backtrace file and line reporting without locals" do
    data = File.read(__FILE__).split("\n__END__\n").last
    fail unless data.start_with? "html"
    template = Tilt::SlimTemplate.new('test.slim', 10) { data }
    begin
      template.render(_Scope.new)
      fail 'should have raised an exception'
    rescue => boom
      assert_kind_of NameError, boom
      line = boom.backtrace.grep(/\Atest\.slim:/).first
      assert line, "Backtrace didn't contain test.slim"
      _file, line, _meth = line.split(":")
      assert_equal '12', line
    end
  end

  it "backtrace file and line reporting with locals" do
    data = File.read(__FILE__).split("\n__END__\n").last
    fail unless data.start_with? "html"
    template = Tilt::SlimTemplate.new('test.slim') { data }
    begin
      template.render(_Scope.new, :name => 'Joe', :foo => 'bar')
    rescue => boom
      assert_kind_of _Scope::MockError, boom
      line = boom.backtrace.first
      file, line, _meth = line.split(":")
      assert_equal 'test.slim', file
      assert_equal '5', line
    end
  end
end

__END__
html
  body
    h1= "Hey #{name}"

    = raise MockError

    p we never get here
