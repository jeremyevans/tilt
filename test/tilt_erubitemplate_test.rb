require_relative 'test_helper'

checked_describe 'tilt/erubi' do
  data = (<<END).freeze
<html>
<body>
    <h1>Hey <%= name %>!</h1>


    <p><% fail %></p>
</body>
</html>
END

  it "registered for '.erubi' files" do
    assert_equal Tilt::ErubiTemplate, Tilt['test.erubi']
    assert_equal Tilt::ErubiTemplate, Tilt['test.html.erubi']
  end

  it "registered above ERB" do
    %w[erb rhtml].each do |ext|
      lazy = Tilt.lazy_map[ext]
      erubi_idx = lazy.index { |klass, file| klass == 'Tilt::ErubiTemplate' }
      erb_idx = lazy.index { |klass, file| klass == 'Tilt::ERBTemplate' }
      assert erubi_idx < erb_idx,
        "#{erubi_idx} should be lower than #{erb_idx}"
    end
  end

  it "preparing and evaluating templates on #render" do
    template = Tilt::ErubiTemplate.new { |t| "Hello World!" }
    assert_equal "Hello World!", template.render
  end

  it "can be rendered more than once" do
    template = Tilt::ErubiTemplate.new { |t| "Hello World!" }
    3.times { assert_equal "Hello World!", template.render }
  end

  it "passing locals" do
    template = Tilt::ErubiTemplate.new { 'Hey <%= name %>!' }
    assert_equal "Hey Joe!", template.render(Object.new, :name => 'Joe')
  end

  it "evaluating in an object scope" do
    template = Tilt::ErubiTemplate.new { 'Hey <%= @name %>!' }
    scope = Object.new
    scope.instance_variable_set :@name, 'Joe'
    assert_equal "Hey Joe!", template.render(scope)
  end

  it "exposing the buffer to the template by default" do
    template = Tilt::ErubiTemplate.new(nil, :bufvar=>'@_out_buf') { '<% self.exposed_buffer = @_out_buf %>hey' }
    scope = Class.new do
      attr_accessor :exposed_buffer
    end.new

    template.render(scope)
    refute_nil scope.exposed_buffer
    assert_equal scope.exposed_buffer, 'hey'
  end

  it "passing a block for yield" do
    template = Tilt::ErubiTemplate.new { 'Hey <%= yield %>!' }
    assert_equal "Hey Joe!", template.render { 'Joe' }
  end

  it "backtrace file and line reporting without locals" do
    template = Tilt::ErubiTemplate.new('test.erubi', 11) { data }
    begin
      template.render
      fail 'should have raised an exception'
    rescue => boom
      assert_kind_of NameError, boom
      line = boom.backtrace.grep(/\Atest\.erubi:/).first
      assert line, "Backtrace didn't contain test.erubi"
      _file, line, _meth = line.split(":")
      assert_equal '13', line
    end
  end

  it "backtrace file and line reporting with locals" do
    template = Tilt::ErubiTemplate.new('test.erubi', 1) { data }
    begin
      template.render(nil, :name => 'Joe', :foo => 'bar')
      fail 'should have raised an exception'
    rescue => boom
      assert_kind_of RuntimeError, boom
      line = boom.backtrace.first
      file, line, _meth = line.split(":")
      assert_equal 'test.erubi', file
      assert_equal '6', line
    end
  end

  it "respects embedded fixed locals that are empty" do
    template = Tilt::ErubiTemplate.new { <<DATA }
<%# locals: () %>
1
DATA
    assert_equal "1", template.render(nil).strip
    assert_raises(ArgumentError) { template.render(nil, :something => true) }
  end

  it "respects embedded fixed locals with optional keyword argument" do
    template = Tilt::ErubiTemplate.new { <<DATA }
<%# locals: (name: "foo") %>
<%= name %>
DATA
    assert_equal "foo", template.render(nil).strip
    assert_equal "bar", template.render(nil, :name => "bar").strip
  end

  it "respects embedded fixed locals with required keyword argument" do
    template = Tilt::ErubiTemplate.new{ <<DATA }
<%# locals: (name:) %>
<%= name %>
DATA
    assert_raises(ArgumentError) { template.render(nil) }
    assert_equal "bar", template.render(nil, :name => "bar").strip
  end if RUBY_VERSION >= '2.1'

  it "respects embedded fixed locals with optional keyword argument and keyword splat" do
    template = Tilt::ErubiTemplate.new { <<DATA }
<%# locals: (name: "foo", **args) %>
<%= name + args[:bar].to_s %>
DATA
    assert_equal "foo", template.render(nil).strip
    assert_equal "barbaz", template.render(nil, :name => "bar", :bar=>"baz").strip
  end

  it "respects embedded fixed locals with positional argument" do
    template = Tilt::ErubiTemplate.new { <<DATA }
<%# locals: (args) %>
<%= args[:name] %>
DATA
    assert_raises(ArgumentError) { template.render(nil) }
    assert_equal "bar", template.render(nil, :name => "bar").strip
  end

  it "respects embedded fixed locals with block argument" do
    template = Tilt::ErubiTemplate.new { <<DATA }
<%# locals: (name: "foo", &block) %>
<%= block.call(name) %>
DATA
    assert_equal "FOO", template.render(nil, &:upcase).strip
    assert_equal "BAR", template.render(nil, :name => "bar", &:upcase).strip
  end

  it "respects :fixed_locals option" do
    template = Tilt::ErubiTemplate.new(fixed_locals: '(name: "foo")') { "<%= name %>" }
    assert_equal "foo", template.render(nil).strip
    assert_equal "bar", template.render(nil, :name => "bar").strip
  end

  it "respects :fixed_locals option in preference to embedded fixed locals" do
    template = Tilt::ErubiTemplate.new(fixed_locals: '(name: "foo")') { <<DATA }
<%# locals: () %>
1
DATA
    assert_equal "1", template.render(nil).strip
    assert_equal "1", template.render(nil, :name => "bar").strip
  end

  it "respects :fixed_locals option in preference to :default_fixed_locals option" do
    template = Tilt::ErubiTemplate.new(fixed_locals: '(name: "foo")', default_fixed_locals: '(name: "baz")') { "<%= name %>" }
    assert_equal "foo", template.render(nil).strip
    assert_equal "bar", template.render(nil, :name => "bar").strip
  end

  it "respects :default_fixed_locals option if there are no embedded fixed locals" do
    template = Tilt::ErubiTemplate.new(default_fixed_locals: '(name: "foo")') { "<%= name %>" }
    assert_equal "foo", template.render(nil).strip
    assert_equal "bar", template.render(nil, :name => "bar").strip
  end

  it "respects embedded fixed locals in preference to :default_fixed_locals option" do
    template = Tilt::ErubiTemplate.new(default_fixed_locals: '(name: "foo")') { <<DATA }
<%# locals: () %>
1
DATA
    assert_equal "1", template.render(nil).strip
    assert_raises(ArgumentError) { template.render(nil, :something => true) }
  end

  it "ignores embedded fixed locals when Tilt.extract_fixed_locals is true and extract_fixed_locals: false option is given" do
    template = Tilt::ErubiTemplate.new(extract_fixed_locals: false) { <<DATA }
<%# locals: () %>
1
DATA
    assert_equal "1", template.render(nil).strip
    assert_equal "1", template.render(nil, :something=>true).strip
  end

  it "handles eager compiling when embedded fixed locals and :scope_class are present" do
    template = Tilt::ErubiTemplate.new(scope_class: Object) { <<DATA }
<%# locals: () %>
1
DATA
    assert_equal "1", template.render(nil).strip
    assert_raises(ArgumentError) { template.render(nil, :something => true) }
  end

  without_extract_fixed_locals "ignores embedded fixed locals when Tilt.extract_fixed_locals is false" do
    template = Tilt::ErubiTemplate.new { <<DATA }
<%# locals: () %>
1
DATA
    assert_equal "1", template.render(nil).strip
    assert_equal "1", template.render(nil, :something=>true).strip
  end

  without_extract_fixed_locals "respects embedded fixed locals when Tilt.extract_fixed_locals is false and :extract_fixed_locals option is given" do
    template = Tilt::ErubiTemplate.new(extract_fixed_locals: true) { <<DATA }
<%# locals: () %>
1
DATA
    assert_equal "1", template.render(nil).strip
    assert_raises(ArgumentError) { template.render(nil, :something => true) }
  end

  without_extract_fixed_locals "respects :fixed_locals option when Tilt.extract_fixed_locals is false" do
    template = Tilt::ErubiTemplate.new(fixed_locals: '(name: "foo")') { "<%= name %>" }
    assert_equal "foo", template.render(nil).strip
    assert_equal "bar", template.render(nil, :name => "bar").strip
  end

  it "erubi template options" do
    template = Tilt::ErubiTemplate.new(nil, :escapefunc=> 'h') { 'Hey <%== @name %>!' }
    scope = Object.new
    def scope.h(s) s * 2 end
    scope.instance_variable_set :@name, 'Joe'
    assert_equal "Hey JoeJoe!", template.render(scope)
  end

  it "using an instance variable as the outvar" do
    template = Tilt::ErubiTemplate.new(nil, :outvar => '@buf') { "<%= 1 + 1 %>" }
    scope = Object.new
    scope.instance_variable_set(:@buf, 'original value')
    assert_equal '2', template.render(scope)
    assert_equal 'original value', scope.instance_variable_get(:@buf)
  end

  it "using Erubi::CaptureEndEngine subclass via :engine_class option" do
    require 'erubi/capture_end'
    def self.bar
      @a << "a"
      yield
      @a << 'b'
      @a.upcase
    end
    template = Tilt::ErubiTemplate.new(nil, :engine_class => ::Erubi::CaptureEndEngine, :bufvar=>'@a') { 'c<%|= bar do %>d<%| end %>e' }
    assert_equal "cADBe", template.render(self)
  end

  it "using :escape_html => true option" do
    template = Tilt::ErubiTemplate.new(nil, :escape_html => true) { |t| %(<%= "<p>Hello World!</p>" %>) }
    assert_equal "&lt;p&gt;Hello World!&lt;/p&gt;", template.render
  end

  it "using :escape_html => false option" do
    template = Tilt::ErubiTemplate.new(nil, :escape_html => false) { |t| %(<%= "<p>Hello World!</p>" %>) }
    assert_equal "<p>Hello World!</p>", template.render
  end

  it "erubi default does not escape html" do
    template = Tilt::ErubiTemplate.new { |t| %(<%= "<p>Hello World!</p>" %>) }
    assert_equal "<p>Hello World!</p>", template.render
  end

  it "does not modify options argument" do
    options_hash = {:escape_html => true}
    Tilt::ErubiTemplate.new(nil, options_hash) { |t| "Hello World!" }
    assert_equal({:escape_html => true}, options_hash)
  end

  if RUBY_VERSION >= '2.3'
    it "uses frozen literal strings if :freeze option is used" do
      template = Tilt::ErubiTemplate.new(nil, :freeze => true) { |t| %(<%= "".frozen? %>) }
      assert_equal "true", template.render
    end
  end
end
