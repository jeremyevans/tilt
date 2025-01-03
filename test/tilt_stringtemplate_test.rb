require_relative 'test_helper'
require 'tilt/string'

data = (<<'END').freeze
<html>
<body>
  <h1>Hey #{name}!</h1>


  <p>#{fail}</p>
</body>
</html>
END

describe 'tilt/string' do
  it "registered for '.str' files" do
    assert_equal Tilt::StringTemplate, Tilt['test.str']
  end

  it "loading and evaluating templates on #render" do
    template = Tilt::StringTemplate.new { |t| "Hello World!" }
    assert_equal "Hello World!", template.render
  end

  it "can be rendered more than once" do
    template = Tilt::StringTemplate.new { |t| "Hello World!" }
    3.times { assert_equal "Hello World!", template.render }
  end

  it "passing locals" do
    template = Tilt::StringTemplate.new { 'Hey #{name}!' }
    assert_equal "Hey Joe!", template.render(Object.new, :name => 'Joe')
  end

  it "evaluating in an object scope" do
    template = Tilt::StringTemplate.new { 'Hey #{@name}!' }
    scope = Object.new
    scope.instance_variable_set :@name, 'Joe'
    assert_equal "Hey Joe!", template.render(scope)
  end

  it "passing a block for yield" do
    template = Tilt::StringTemplate.new { 'Hey #{yield}!' }
    assert_equal "Hey Joe!", template.render { 'Joe' }
    assert_equal "Hey Moe!", template.render { 'Moe' }
  end

  it "multiline templates" do
    template = Tilt::StringTemplate.new { "Hello\nWorld!\n" }
    assert_equal "Hello\nWorld!\n", template.render
  end

  it "backtrace file and line reporting without locals" do
    template = Tilt::StringTemplate.new('test.str', 11) { data }
    begin
      template.render
      fail 'should have raised an exception'
    rescue => boom
      assert_kind_of NameError, boom
      line = boom.backtrace.grep(/\Atest\.str:/).first
      assert line, "Backtrace didn't contain test.str"
      _file, line, _meth = line.split(":")
      skip if heredoc_line_number_bug?
      assert_equal '13', line
    end
  end

  it "backtrace file and line reporting with locals" do
    template = Tilt::StringTemplate.new('test.str', 1) { data }
    begin
      template.render(nil, :name => 'Joe', :foo => 'bar')
      fail 'should have raised an exception'
    rescue => boom
      assert_kind_of RuntimeError, boom
      line = boom.backtrace.first
      file, line, _meth = line.split(":")
      assert_equal 'test.str', file
      skip if heredoc_line_number_bug?
      assert_equal '6', line
    end
  end
end

describe 'tilt/string (compiled)' do
  after do
    GC.start
  end

  _Scope = Class.new

  it "compiling template source to a method" do
    template = Tilt::StringTemplate.new { |t| "Hello World!" }
    template.render(_Scope.new)
    method = template.send(:compiled_method, [])
    assert_kind_of UnboundMethod, method
  end

  it "loading and evaluating templates on #render" do
    template = Tilt::StringTemplate.new { |t| "Hello World!" }
    assert_equal "Hello World!", template.render(_Scope.new)
  end

  it "passing locals" do
    template = Tilt::StringTemplate.new { 'Hey #{name}!' }
    assert_equal "Hey Joe!", template.render(_Scope.new, :name => 'Joe')
    assert_equal "Hey Moe!", template.render(_Scope.new, :name => 'Moe')
  end

  it "evaluating in an object scope" do
    template = Tilt::StringTemplate.new { 'Hey #{@name}!' }
    scope = _Scope.new
    scope.instance_variable_set :@name, 'Joe'
    assert_equal "Hey Joe!", template.render(scope)
    scope.instance_variable_set :@name, 'Moe'
    assert_equal "Hey Moe!", template.render(scope)
  end

  it "passing a block for yield" do
    template = Tilt::StringTemplate.new { 'Hey #{yield}!' }
    assert_equal "Hey Joe!", template.render(_Scope.new) { 'Joe' }
    assert_equal "Hey Moe!", template.render(_Scope.new) { 'Moe' }
  end

  it "multiline templates" do
    template = Tilt::StringTemplate.new { "Hello\nWorld!\n" }
    assert_equal "Hello\nWorld!\n", template.render(_Scope.new)
  end


  it "template with '}'" do
    template = Tilt::StringTemplate.new { "Hello }" }
    assert_equal "Hello }", template.render
  end

  it "backtrace file and line reporting without locals" do
    template = Tilt::StringTemplate.new('test.str', 11) { data }
    begin
      template.render(_Scope.new)
      fail 'should have raised an exception'
    rescue => boom
      assert_kind_of NameError, boom
      line = boom.backtrace.first
      line = boom.backtrace.grep(/\Atest\.str:/).first
      assert line, "Backtrace didn't contain test.str"
      _file, line, _meth = line.split(":")
      skip if heredoc_line_number_bug?
      assert_equal '13', line
    end
  end

  it "backtrace file and line reporting with locals" do
    template = Tilt::StringTemplate.new('test.str') { data }
    begin
      template.render(_Scope.new, :name => 'Joe', :foo => 'bar')
      fail 'should have raised an exception'
    rescue => boom
      assert_kind_of RuntimeError, boom
      line = boom.backtrace.first
      file, line, _meth = line.split(":")
      assert_equal 'test.str', file
      skip if heredoc_line_number_bug?
      assert_equal '6', line
    end
  end

  it "respects embedded fixed locals that are empty" do
    template = Tilt::StringTemplate.new { <<'DATA' }
#{# locals: ()
1}
DATA
    assert_equal "1\n", template.render(nil)
    assert_raises(ArgumentError) { template.render(nil, :something => true) }
  end

  it "respects embedded fixed locals with optional keyword argument" do
    template = Tilt::StringTemplate.new { <<'DATA' }
#{# locals: (name: "foo")
name}
DATA
    assert_equal "foo\n", template.render(nil)
    assert_equal "bar\n", template.render(nil, :name => "bar")
  end

  it "respects embedded fixed locals with required keyword argument" do
    template = Tilt::StringTemplate.new { <<'DATA' }
#{# locals: (name:)
name}
DATA
    assert_raises(ArgumentError) { template.render(nil) }
    assert_equal "bar\n", template.render(nil, :name => "bar")
  end if RUBY_VERSION >= '2.1'

  it "respects embedded fixed locals with optional keyword argument and keyword splat" do
    template = Tilt::StringTemplate.new { <<'DATA' }
#{# locals: (name: "foo", **args)
name + args[:bar].to_s}
DATA
    assert_equal "foo\n", template.render(nil)
    assert_equal "barbaz\n", template.render(nil, :name => "bar", :bar=>"baz")
  end

  it "respects embedded fixed locals with positional argument" do
    template = Tilt::StringTemplate.new { <<'DATA' }
#{# locals: (args)
args[:name]}
DATA
    assert_raises(ArgumentError) { template.render(nil) }
    assert_equal "bar\n", template.render(nil, :name => "bar")
  end

  it "respects embedded fixed locals with block argument" do
    template = Tilt::StringTemplate.new { <<'DATA' }
#{# locals: (name: "foo", &block)
block.call(name)}
DATA
    assert_equal "FOO\n", template.render(nil, &:upcase)
    assert_equal "BAR\n", template.render(nil, :name => "bar", &:upcase)
  end

  it "respects :fixed_locals option" do
    template = Tilt::StringTemplate.new(fixed_locals: '(name: "foo")') { '#{name}\n' }
    assert_equal "foo\n", template.render(nil)
    assert_equal "bar\n", template.render(nil, :name => "bar")
  end

  it "respects :fixed_locals option in preference to :default_fixed_locals option" do
    template = Tilt::StringTemplate.new(fixed_locals: '(name: "foo")', default_fixed_locals: '(name: "baz")') { '#{name}\n' }
    assert_equal "foo", template.render(nil).strip
    assert_equal "bar", template.render(nil, :name => "bar").strip
  end

  it "respects :default_fixed_locals option if there are no embedded fixed locals" do
    template = Tilt::StringTemplate.new(default_fixed_locals: '(name: "foo")') { '#{name}\n' }
    assert_equal "foo", template.render(nil).strip
    assert_equal "bar", template.render(nil, :name => "bar").strip
  end

  it "respects embedded fixed locals in preference to :default_fixed_locals option" do
    template = Tilt::StringTemplate.new(default_fixed_locals: '(name: "foo")') { <<'DATA' }
#{# locals: ()
1}
DATA
    assert_equal "1", template.render(nil).strip
    assert_raises(ArgumentError) { template.render(nil, :something => true) }
  end

  it "ignores embedded fixed locals when Tilt.extract_fixed_locals is true and extract_fixed_locals: false option is given" do
    template = Tilt::StringTemplate.new(extract_fixed_locals: false) { <<'DATA' }
#{# locals: ()
1}
DATA
    assert_equal "1", template.render(nil).strip
    assert_equal "1", template.render(nil, :something=>true).strip
  end

  it "handles eager compiling when embedded fixed locals and :scope_class are present" do
    template = Tilt::StringTemplate.new(scope_class: Object) { <<'DATA' }
#{# locals: ()
1}
DATA
    assert_equal "1", template.render(nil).strip
    assert_raises(ArgumentError) { template.render(nil, :something => true) }
  end

  without_extract_fixed_locals "ignores embedded fixed locals when Tilt.extract_fixed_locals is false" do
    template = Tilt::StringTemplate.new { <<'DATA' }
#{# locals: ()
1}
DATA
    assert_equal "1", template.render(nil).strip
    assert_equal "1", template.render(nil, :something=>true).strip
  end

  without_extract_fixed_locals "respects embedded fixed locals when Tilt.extract_fixed_locals is false and :extract_fixed_locals option is given" do
    template = Tilt::StringTemplate.new(extract_fixed_locals: true) { <<'DATA' }
#{# locals: ()
1}
DATA
    assert_equal "1", template.render(nil).strip
    assert_raises(ArgumentError) { template.render(nil, :something => true) }
  end

  without_extract_fixed_locals "respects :fixed_locals option when Tilt.extract_fixed_locals is false" do
    template = Tilt::StringTemplate.new(fixed_locals: '(name: "foo")') { '#{name}\n' }
    assert_equal "foo\n", template.render(nil)
    assert_equal "bar\n", template.render(nil, :name => "bar")
  end

  if RUBY_VERSION >= '2.3'
    it "uses frozen literal strings if :freeze option is used" do
      template = Tilt::StringTemplate.new(nil, :freeze => true) { |t| '#{"".frozen?}' }
      assert_equal "true", template.render
    end
  end
end
