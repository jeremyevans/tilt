require_relative 'test_helper'

begin
  require 'tilt/builder'
rescue LoadError => e
  warn "Tilt::BuilderTemplate (disabled): #{e.message}"
else
  describe 'tilt/builder' do
    it "registered for '.builder' files" do
      assert_equal Tilt::BuilderTemplate, Tilt['test.builder']
      assert_equal Tilt::BuilderTemplate, Tilt['test.xml.builder']
    end

    it "preparing and evaluating the template on #render" do
      template = Tilt::BuilderTemplate.new { |t| "xml.em 'Hello World!'" }
      3.times { assert_equal "<em>Hello World!</em>\n", template.render }
    end

    it "passing locals" do
      template = Tilt::BuilderTemplate.new { "xml.em('Hey ' + name + '!')" }
      assert_equal "<em>Hey Joe!</em>\n", template.render(Object.new, :name => 'Joe')
    end

    it "passing :xml in locals" do
      template = Tilt::BuilderTemplate.new { "xml.div { xml.em('Hey') }" }
      assert_equal "<div><em>Hey</em></div>", template.render(nil, xml: ::Builder::XmlMarkup.new(:indent => 0))
    end

    it "evaluating in an object scope" do
      template = Tilt::BuilderTemplate.new { "xml.em('Hey ' + @name + '!')" }
      scope = Object.new
      scope.instance_variable_set :@name, 'Joe'
      assert_equal "<em>Hey Joe!</em>\n", template.render(scope)
    end

    it "passing a block for yield" do
      template = Tilt::BuilderTemplate.new { "xml.em('Hey ' + yield + '!')" }
      3.times { assert_equal "<em>Hey Joe!</em>\n", template.render { 'Joe' }}
    end

    it "block style templates" do
      template =
        Tilt::BuilderTemplate.new do |t|
          lambda { |xml| xml.em('Hey Joe!') }
        end
      assert_equal "<em>Hey Joe!</em>\n", template.render
    end

    it "options can be overridden" do
      template = Tilt::BuilderTemplate.new(:indent => 0) { "xml.div { xml.em('Hey') }" }
      assert_equal "<div><em>Hey</em></div>", template.render
    end

    it "can re-use locals for multiple calls" do
      locals = { :name => "world" }
      template = Tilt::BuilderTemplate.new(:indent => 0) { "xml.em name" }
      3.times do
        assert_equal "<em>world</em>", template.render(self, locals)
      end
    end

    it "allows nesting raw XML" do
      subtemplate = Tilt::BuilderTemplate.new { "xml.em 'Hello World!'" }
      template = Tilt::BuilderTemplate.new { "xml.strong { xml << yield }" }
      3.times do
        options = { :xml => Builder::XmlMarkup.new }
        assert_equal "<strong>\n<em>Hello World!</em>\n</strong>\n",
          template.render(options) { subtemplate.render(options) }
      end
    end
  end
end
