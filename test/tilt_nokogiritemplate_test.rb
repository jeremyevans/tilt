require_relative 'test_helper'

checked_describe 'tilt/nokogiri' do
  it "registered for '.nokogiri' files" do
    assert_equal Tilt::NokogiriTemplate, Tilt['test.nokogiri']
    assert_equal Tilt::NokogiriTemplate, Tilt['test.xml.nokogiri']
  end

  it "preparing and evaluating the template on #render" do
    template = Tilt::NokogiriTemplate.new { |t| "xml.em 'Hello World!'" }
    3.times do
      doc = Nokogiri.XML template.render
      assert_equal 'Hello World!', doc.root.text
      assert_equal 'em', doc.root.name
    end
  end

  it "passing locals" do
    template = Tilt::NokogiriTemplate.new { "xml.em('Hey ' + name + '!')" }
    doc = Nokogiri.XML template.render(Object.new, :name => 'Joe')
    assert_equal 'Hey Joe!', doc.root.text
    assert_equal 'em', doc.root.name
  end

  it "passing locals with :xml" do
    template = Tilt::NokogiriTemplate.new { "xml.em('Hey ' + name + '!')" }
    doc = Nokogiri.XML template.render(Object.new, :name => 'Joe', :xml => Nokogiri::XML::Builder.new)
    assert_equal 'Hey Joe!', doc.root.text
    assert_equal 'em', doc.root.name
  end

  it "evaluating in an object scope" do
    template = Tilt::NokogiriTemplate.new { "xml.em('Hey ' + @name + '!')" }
    scope = Object.new
    scope.instance_variable_set :@name, 'Joe'
    doc = Nokogiri.XML template.render(scope)
    assert_equal 'Hey Joe!', doc.root.text
    assert_equal 'em', doc.root.name
  end

  it "passing a block for yield" do
    template = Tilt::NokogiriTemplate.new { "xml.em('Hey ' + yield + '!')" }
    3.times do
      doc = Nokogiri.XML template.render { 'Joe' }
      assert_equal 'Hey Joe!', doc.root.text
      assert_equal 'em', doc.root.name
    end
  end

  it "block style templates" do
    template =
      Tilt::NokogiriTemplate.new do |t|
        lambda { |xml| xml.em('Hey Joe!') }
      end
    doc = Nokogiri.XML template.render
    assert_equal 'Hey Joe!', doc.root.text
    assert_equal 'em', doc.root.name
  end

  it "allows nesting raw XML, API-compatible to Builder" do
    subtemplate = Tilt::NokogiriTemplate.new { "xml.em 'Hello World!'" }
    template = Tilt::NokogiriTemplate.new { "xml.strong { xml << yield }" }
    3.times do
      options = { :xml => Nokogiri::XML::Builder.new }
      doc = Nokogiri.XML(template.render(options) { subtemplate.render(options) })
      assert_equal 'Hello World!', doc.root.text.strip
      assert_equal 'strong', doc.root.name
    end
  end

  it "doesn't modify self when template is a string" do
    template = Tilt::NokogiriTemplate.new { "xml.root { xml.child @hello }" }
    scope = Object.new
    scope.instance_variable_set(:@hello, "Hello World!")

    3.times do
      doc = Nokogiri.XML(template.render(scope))
      assert_equal "Hello World!", doc.text.strip
    end
  end
end
