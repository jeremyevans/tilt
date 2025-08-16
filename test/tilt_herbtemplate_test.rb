require_relative 'test_helper'

begin
  require 'tilt/herb'

  describe 'tilt/herb' do
    it "registered for '.erb' files" do
      assert_equal Tilt::HerbTemplate, Tilt['test.erb']
      assert_equal Tilt::HerbTemplate, Tilt['test.html.erb']
    end

    it "registered for '.herb' files" do
      assert_equal Tilt::HerbTemplate, Tilt['test.herb']
      assert_equal Tilt::HerbTemplate, Tilt['test.html.herb']
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

    class MockOutputVariableScope
      attr_accessor :exposed_buffer
    end

    it "exposing the buffer to the template by default" do
      template = Tilt::HerbTemplate.new(nil, bufvar: '@_out_buf') { '<% self.exposed_buffer = @_out_buf %>hey' }
      scope = MockOutputVariableScope.new
      template.render(scope)
      refute_nil scope.exposed_buffer
      assert_equal scope.exposed_buffer, 'hey'
    end

    it "passing a block for yield" do
      template = Tilt::HerbTemplate.new { 'Hey <%= yield %>!' }
      assert_equal "Hey Joe!", template.render { 'Joe' }
    end

    it "backtrace file and line reporting without locals" do
      data = File.read(__FILE__).split("\n__END__\n").last
      fail unless data[0] == ?<
      template = Tilt::HerbTemplate.new('test.herb', 11) { data }

      begin
        template.render
        fail 'should have raised an exception'
      rescue => boom
        assert_kind_of NameError, boom

        line = boom.backtrace.grep(/^test\.herb:/).first
        assert line, "Backtrace didn't contain test.herb"

        _file, line, _meth = line.split(":")
        assert_equal '14', line
      end
    end

    it "backtrace file and line reporting with locals" do
      data = File.read(__FILE__).split("\n__END__\n").last
      fail unless data[0] == ?<
      template = Tilt::HerbTemplate.new('test.herb', 1) { data }

      begin
        template.render(nil, name: 'Joe', foo: 'bar')
        fail 'should have raised an exception'
      rescue => boom
        assert_kind_of NameError, boom

        line = boom.backtrace.first
        file, line, _meth = line.split(":")

        assert_equal 'test.herb', file
        assert_equal '4', line
      end
    end

    it "herb template options" do
      template = Tilt::HerbTemplate.new(nil, escape: true) { 'Hey <%= @name %>!' }
      scope = Object.new
      scope.instance_variable_set :@name, '<script>alert("xss")</script>'
      result = template.render(scope)
      assert_equal "Hey &lt;script&gt;alert(&quot;xss&quot;)&lt;/script&gt;!", result
    end

    it "evaluating ruby code" do
      template = Tilt::HerbTemplate.new { '<% 2.times do %>Hey <% end %>' }
      assert_equal "Hey Hey ", template.render
    end

    it "evaluating ruby code with locals" do
      template = Tilt::HerbTemplate.new { '<% count.times do %>Hey <% end %>' }
      assert_equal "Hey Hey Hey ", template.render(Object.new, count: 3)
    end

    it "html structure and attributes" do
      template = Tilt::HerbTemplate.new { '<div class="container" id="<%= element_id %>">Content</div>' }
      assert_equal '<div class="container" id="main">Content</div>', template.render(Object.new, element_id: 'main')
    end

    it "freeze option should freeze string literals" do
      template = Tilt::HerbTemplate.new(nil, freeze: true) { 'Hello <%= name %>!' }
      assert template.freeze_string_literals?
    end

    it "custom buffer variable" do
      template = Tilt::HerbTemplate.new(nil, bufvar: '_custom_buf') { 'Hello World!' }
      assert_equal "Hello World!", template.render
    end

    it "handling void elements" do
      template = Tilt::HerbTemplate.new { '<img src="<%= src %>" alt="Photo"><br><input type="text">' }
      result = template.render(Object.new, src: 'photo.jpg')

      assert_equal '<img src="photo.jpg" alt="Photo"><br><input type="text">', result
    end

    it "handling erb comments" do
      template = Tilt::HerbTemplate.new { "Before\n<%# This is a comment %>\nAfter" }
      assert_equal "Before\n\nAfter", template.render
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
      result = template.render(Object.new, items: ['apple', 'banana', 'cherry'])

      assert_equal "<ul><li>apple</li><li>banana</li><li>cherry</li></ul>", result
    end

    it "catches unclosed HTML tags" do
      error = assert_raises(Herb::Engine::CompilationError) do
        Tilt::HerbTemplate.new { '<div><span>Content</div>' }
      end

      assert_match(/Tag `<span>` opened at .* was never closed/, error.message)
      assert_match(/UnclosedElement/, error.message)
      assert_match(/TagNamesMismatch/, error.message)
    end

    it "catches mismatched HTML tags" do
      error = assert_raises(Herb::Engine::CompilationError) do
        Tilt::HerbTemplate.new { '<div><span>Content</span></p>' }
      end

      assert_match(/Opening tag `<div>` .* closed with `<\/p>`/, error.message)
      assert_match(/TagNamesMismatch/, error.message)
    end

    it "allows properly nested HTML tags" do
      template = Tilt::HerbTemplate.new { '<div><span>Content</span></div>' }
      assert_equal '<div><span>Content</span></div>', template.render
    end

    it "catches unclosed ERB blocks" do
      error = assert_raises(Herb::Engine::CompilationError) do
        Tilt::HerbTemplate.new { '<% if true %><div>Missing end</div>' }
      end

      assert_match(/expected an `end` to close the conditional/, error.message)
      assert error.message.include?('Missing') && error.message.include?('end')
      assert_match(/Compilation failed/, error.message)
    end

    it "allows ERB blocks spanning HTML tags" do
      template = Tilt::HerbTemplate.new { '<div><% if true %></div><% end %>' }
      assert_equal '<div></div>', template.render
    end

    it "catches ERB syntax errors" do
      error = assert_raises(Herb::Engine::CompilationError) do
        Tilt::HerbTemplate.new { '<%= if true %>' }
      end

      assert_match(/\[source\]/, error.message)
      assert_match(/Compilation failed/, error.message)

      clean_message = error.message.gsub(/\e\[[0-9;]*m/, '')
      assert clean_message.include?('if true')
    end

    it "provides helpful error messages with context" do
      error = assert_raises(Herb::Engine::CompilationError) do
        Tilt::HerbTemplate.new { "<div>\n  <span>Unclosed\n</div>" }
      end

      assert_match(/\[source\]/, error.message)
      assert_match(/span/, error.message)
      assert_match(/Unclosed/, error.message)
    end
  end

rescue LoadError => boom
  warn "Tilt::HerbTemplate (disabled)"
  warn boom.message
end

__END__
<html>
  <body>
    <h1>Hey <%= undefined_variable %>!</h1>
    <p>
      <% if @name %>
        <%= raise 'test error in @name' %>
      <% end %>
    </p>
  </body>
</html>
