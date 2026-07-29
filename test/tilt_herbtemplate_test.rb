require_relative 'test_helper'

checked_describe 'tilt/herb' do
  data = (<<END).freeze
<html>
<body>
    <h1>Hey <%= name %>!</h1>


    <p><% fail %></p>
</body>
</html>
END

  it "registered for '.herb' files" do
    assert_equal Tilt::HerbTemplate, Tilt['test.herb']
    assert_equal Tilt::HerbTemplate, Tilt['test.html.herb']
  end

  it "registered for '.html.erb' files" do
    assert_equal Tilt::HerbTemplate, Tilt['test.html.erb']
  end

  it "not registered for '.erb' files" do
    refute_equal Tilt::HerbTemplate, Tilt['test.erb']
  end

  it "preparing and evaluating templates on #render" do
    template = Tilt::HerbTemplate.new { |t| "Hello World!" }
    assert_equal "Hello World!", template.render
  end

  it "can be rendered more than once" do
    template = Tilt::HerbTemplate.new { |t| "Hello World!" }
    3.times { assert_equal "Hello World!", template.render }
  end

  it "passing locals" do
    template = Tilt::HerbTemplate.new { 'Hey <%= name %>!' }
    assert_equal "Hey Joe!", template.render(Object.new, name: 'Joe')
  end

  it "evaluating in an object scope" do
    template = Tilt::HerbTemplate.new { 'Hey <%= @name %>!' }
    scope = Object.new
    scope.instance_variable_set :@name, 'Joe'
    assert_equal "Hey Joe!", template.render(scope)
  end

  it "exposing the buffer to the template by default" do
    template = Tilt::HerbTemplate.new(nil, bufvar: '@_out_buf') { '<% self.exposed_buffer = @_out_buf %>hey' }

    scope = Class.new do
      attr_accessor :exposed_buffer
    end.new

    template.render(scope)
    refute_nil scope.exposed_buffer
    assert_equal scope.exposed_buffer, 'hey'
  end

  it "passing a block for yield" do
    template = Tilt::HerbTemplate.new { 'Hey <%= yield %>!' }
    assert_equal "Hey Joe!", template.render { 'Joe' }
  end

  it "backtrace file and line reporting without locals" do
    template = Tilt::HerbTemplate.new('test.herb', 11) { data }

    begin
      template.render
      fail 'should have raised an exception'
    rescue => boom
      assert_kind_of NameError, boom

      line = boom.backtrace.grep(/\Atest\.herb:/).first
      assert line, "Backtrace didn't contain test.herb"

      _file, line, _meth = line.split(":")
      assert_equal '13', line
    end
  end

  it "backtrace file and line reporting with locals" do
    template = Tilt::HerbTemplate.new('test.herb', 1) { data }
    begin
      template.render(nil, name: 'Joe', foo: 'bar')
      fail 'should have raised an exception'
    rescue => boom
      assert_kind_of RuntimeError, boom

      line = boom.backtrace.first
      file, line, _meth = line.split(":")

      assert_equal 'test.herb', file
      assert_equal '6', line
    end
  end

  it "respects embedded fixed locals that are empty" do
    template = Tilt::HerbTemplate.new { <<DATA }
<%# locals: () %>
1
DATA
    assert_equal "1", template.render(nil).strip
    assert_raises(ArgumentError) { template.render(nil, something: true) }
  end

  it "respects embedded fixed locals with optional keyword argument" do
    template = Tilt::HerbTemplate.new { <<DATA }
<%# locals: (name: "foo") %>
<%= name %>
DATA
    assert_equal "foo", template.render(nil).strip
    assert_equal "bar", template.render(nil, name: "bar").strip
  end

  it "respects embedded fixed locals with required keyword argument" do
    template = Tilt::HerbTemplate.new { <<DATA }
<%# locals: (name:) %>
<%= name %>
DATA
    assert_raises(ArgumentError) { template.render(nil) }
    assert_equal "bar", template.render(nil, name: "bar").strip
  end

  it "respects :fixed_locals option" do
    template = Tilt::HerbTemplate.new(fixed_locals: '(name: "foo")') { "<%= name %>" }
    assert_equal "foo", template.render(nil).strip
    assert_equal "bar", template.render(nil, name: "bar").strip
  end

  without_extract_fixed_locals "ignores embedded fixed locals when Tilt.extract_fixed_locals is false" do
    template = Tilt::HerbTemplate.new { <<DATA }
<%# locals: () %>
1
DATA
    assert_equal "1", template.render(nil).strip
    assert_equal "1", template.render(nil, something: true).strip
  end

  it "handles eager compiling when embedded fixed locals and :scope_class are present" do
    template = Tilt::HerbTemplate.new(scope_class: Object) { <<DATA }
<%# locals: () %>
1
DATA
    assert_equal "1", template.render(nil).strip
    assert_raises(ArgumentError) { template.render(nil, something: true) }
  end

  it "herb template options" do
    template = Tilt::HerbTemplate.new(nil, escapefunc: 'h') { 'Hey <%== @name %>!' }
    scope = Object.new
    def scope.h(s) s * 2 end
    scope.instance_variable_set :@name, 'Joe'
    assert_equal "Hey JoeJoe!", template.render(scope)
  end

  it "using an instance variable as the outvar" do
    template = Tilt::HerbTemplate.new(nil, outvar: '@buf') { "<%= 1 + 1 %>" }
    scope = Object.new
    scope.instance_variable_set(:@buf, 'original value')
    assert_equal '2', template.render(scope)
    assert_equal 'original value', scope.instance_variable_get(:@buf)
  end

  it "using a custom engine class via the :engine_class option" do
    engine_class = Class.new(Herb::Engine)
    template = Tilt::HerbTemplate.new(nil, engine_class: engine_class) { "Hello World!" }
    assert_equal "Hello World!", template.render
  end

  it "using escape: true option" do
    template = Tilt::HerbTemplate.new(nil, escape: true) { |t| %(<%= "<p>Hello World!</p>" %>) }
    assert_equal "&lt;p&gt;Hello World!&lt;/p&gt;", template.render
  end

  it "using escape_html: true option" do
    template = Tilt::HerbTemplate.new(nil, escape_html: true) { |t| %(<%= "<p>Hello World!</p>" %>) }
    assert_equal "&lt;p&gt;Hello World!&lt;/p&gt;", template.render
  end

  it "using escape_html: false option" do
    template = Tilt::HerbTemplate.new(nil, escape_html: false) { |t| %(<%= "<p>Hello World!</p>" %>) }
    assert_equal "<p>Hello World!</p>", template.render
  end

  it "herb default does not escape html" do
    template = Tilt::HerbTemplate.new { |t| %(<%= "<p>Hello World!</p>" %>) }
    assert_equal "<p>Hello World!</p>", template.render
  end

  it "does not modify options argument" do
    options_hash = {escape_html: true}
    Tilt::HerbTemplate.new(nil, options_hash) { |t| "Hello World!" }
    assert_equal({escape_html: true}, options_hash)
  end

  it "uses frozen literal strings if :freeze option is used" do
    template = Tilt::HerbTemplate.new(nil, freeze: true) { |t| %(<%= "".frozen? %>) }
    assert_equal "true", template.render
  end

  it "evaluating ruby code" do
    template = Tilt::HerbTemplate.new { '<% 2.times do %>Hey <% end %>' }
    assert_equal "Hey Hey ", template.render
  end

  it "rendering html attributes from locals" do
    template = Tilt::HerbTemplate.new { '<div class="container" id="<%= element_id %>">Content</div>' }
    assert_equal '<div class="container" id="main">Content</div>', template.render(Object.new, element_id: 'main')
  end

  it "escaping attribute values when :escape is used" do
    template = Tilt::HerbTemplate.new(nil, escape: true) { '<div id="<%= id %>"></div>' }
    assert_equal '<div id="a&quot;b"></div>', template.render(Object.new, id: 'a"b')
  end

  it "handling void elements" do
    template = Tilt::HerbTemplate.new { '<img src="<%= src %>" alt="Photo"><br><input type="text">' }
    assert_equal '<img src="photo.jpg" alt="Photo"><br><input type="text">',
      template.render(Object.new, src: 'photo.jpg')
  end

  it "handling erb comments" do
    template = Tilt::HerbTemplate.new { "Before\n<%# This is a comment %>\nAfter" }
    assert_equal "Before\nAfter", template.render
  end

  it "handling html comments" do
    template = Tilt::HerbTemplate.new { "Before\n<!-- This is a comment -->\nAfter" }
    assert_equal "Before\n<!-- This is a comment -->\nAfter", template.render
  end

  it "handles control flow" do
    template = Tilt::HerbTemplate.new do
      '<% if logged_in %><span>Welcome!</span><% else %><span>Please login</span><% end %>'
    end

    assert_equal "<span>Welcome!</span>", template.render(Object.new, logged_in: true)
    assert_equal "<span>Please login</span>", template.render(Object.new, logged_in: false)
  end

  it "handles loops" do
    template = Tilt::HerbTemplate.new { '<ul><% items.each do |item| %><li><%= item %></li><% end %></ul>' }
    assert_equal "<ul><li>apple</li><li>banana</li></ul>",
      template.render(Object.new, items: ['apple', 'banana'])
  end

  it "raises for unclosed html tags" do
    error = assert_raises(Herb::Engine::CompilationError) do
      Tilt::HerbTemplate.new { '<div><span>Content</div>' }
    end

    assert_match(/MissingClosingTag/, error.message)
  end

  it "raises for mismatched html tags" do
    error = assert_raises(Herb::Engine::CompilationError) do
      Tilt::HerbTemplate.new { '<div><span>Content</span></p>' }
    end

    assert_match(/MissingOpeningTag/, error.message)
  end

  it "raises for unclosed erb blocks" do
    error = assert_raises(Herb::Engine::CompilationError) do
      Tilt::HerbTemplate.new { '<% if true %><div>Missing end</div>' }
    end

    assert_match(/expected an `end` to close the conditional/, error.message)
  end

  it "raises for invalid ruby" do
    error = assert_raises(Herb::Engine::CompilationError) do
      Tilt::HerbTemplate.new { '<div><%= "unterminated %></div>' }
    end

    assert_match(/unterminated string/, error.message)
  end
end
