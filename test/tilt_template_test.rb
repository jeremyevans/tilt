require_relative 'test_helper'
require 'tempfile'
require 'tmpdir'
require 'pathname'

_MockTemplate = Class.new(Tilt::Template)

describe "tilt/template" do
  it "needs a file or block" do
    assert_raises(ArgumentError) { Tilt::Template.new }
  end

  it "handles frozen strings with :default_encoding" do
    inst = _MockTemplate.new('foo.erb', default_encoding: 'US-ASCII') {''.freeze}
    assert_equal false, inst.data.frozen?
    assert_equal Encoding::US_ASCII, inst.data.encoding
  end

  it "initializing with a file" do
    inst = _MockTemplate.new('foo.erb') {}
    assert_equal 'foo.erb', inst.file
  end

  it "initializing with a file and line" do
    inst = _MockTemplate.new('foo.erb', 55) {}
    assert_equal 'foo.erb', inst.file
    assert_equal 55, inst.line
  end

  it "initializing with a tempfile" do
    tempfile = Tempfile.new('tilt_template_test')
    inst = _MockTemplate.new(tempfile)
    assert_equal File.basename(tempfile.path), inst.basename
  end

  it "initializing with an object responding to to_path" do
    o = Object.new
    def o.to_path; 'foo.erb' end
    assert_equal 'foo.erb', _MockTemplate.new(o){}.file
  end

  it "initializing with an object not responding to any expected convertor" do
    assert_raises(TypeError) do
      _MockTemplate.new(Object.new)
    end
  end

  it "initializing with a pathname" do
    tempfile = Tempfile.new('tilt_template_test')
    pathname = Pathname.new(tempfile.path)
    inst = _MockTemplate.new(pathname)
    assert_equal File.basename(tempfile.path), inst.basename
  end

  it "initialize with hash that implements #path and #to_path" do
    _SillyHash = Class.new(Hash) do
      def path; end
      def to_path; end
    end

    options = _SillyHash[:key => :value]
    inst = _MockTemplate.new(options) {}
    assert_equal :value, inst.options[:key]
  end

  it "uses correct eval_file" do
    inst = _MockTemplate.new('foo.erb', 55) {}
    assert_equal 'foo.erb', inst.eval_file
  end

  it "uses a default filename for #eval_file when no file provided" do
    inst = _MockTemplate.new { 'Hi' }
    refute_nil inst.eval_file
    assert !inst.eval_file.include?("\n")
  end

  it "calculating template's #basename" do
    inst = _MockTemplate.new('/tmp/templates/foo.html.erb') {}
    assert_equal 'foo.html.erb', inst.basename
  end

  it "calculating the template's #name" do
    inst = _MockTemplate.new('/tmp/templates/foo.html.erb') {}
    assert_equal 'foo', inst.name
  end

  it "handles #basename and #name without file" do
    inst = _MockTemplate.new {}
    assert_nil inst.basename
    assert_nil inst.name
  end

  it "#metadata returns class metdata" do
    assert_equal({}, _MockTemplate.new{}.metadata)
  end

  it "initializing with a data loading block" do
    _MockTemplate.new { |template| "Hello World!" }
  end

  _PreparingMockTemplate = Class.new(Tilt::Template) do
    def prepare
      raise "data must be set" if data.nil?
      @prepared = true
    end
    def prepared? ; @prepared ; end
  end

  it "raises NotImplementedError when #evaluate or #template_source not defined" do
    inst = _PreparingMockTemplate.new { |t| "Hello World!" }
    assert_raises(NotImplementedError) { inst.render }
    assert inst.prepared?
  end

  _SimpleMockTemplate = Class.new(_PreparingMockTemplate) do
    def evaluate(scope, locals, &block)
      raise "should be prepared" unless prepared?
      raise "scope should be present" if scope.nil?
      raise "locals should be present" if locals.nil?
      "<em>#{@data}</em>"
    end
  end

  it "prepares and evaluates the template on #render" do
    inst = _SimpleMockTemplate.new { |t| "Hello World!" }
    assert_equal "<em>Hello World!</em>", inst.render
    assert inst.prepared?
  end

  it 'prepares and evaluates the template on #render with nil arg' do
    inst = _SimpleMockTemplate.new { |t| "Hello World!" }
    assert_equal '<em>Hello World!</em>', inst.render(nil)
    assert inst.prepared?
  end

  _SourceGeneratingMockTemplate = Class.new(_PreparingMockTemplate) do
    def precompiled_template(locals)
      "foo = [] ; foo << %Q{#{data}} ; foo.join"
    end
  end

  it "template_source with locals" do
    inst = _SourceGeneratingMockTemplate.new { |t| 'Hey #{name}!' }
    assert_equal "Hey Joe!", inst.render(Object.new, :name => 'Joe')
    assert inst.prepared?
  end

  it "template_source with locals of strings" do
    inst = _SourceGeneratingMockTemplate.new { |t| 'Hey #{name}!' }
    assert_equal "Hey Joe!", inst.render(Object.new, 'name' => 'Joe')
    assert inst.prepared?
  end

  it "template_source with locals of strings" do
    inst = _SourceGeneratingMockTemplate.new { |t| 'Hey #{name}!' }
    assert_equal "Hey Joe!", inst.render(Object.new, 'name' => 'Joe', :name=>'Joe')
    assert inst.prepared?
  end

  it "template_source with locals having non-variable keys raises error" do
    inst = _SourceGeneratingMockTemplate.new { |t| '1 + 2 = #{_answer}' }
    err = assert_raises(RuntimeError) { inst.render(Object.new, 'ANSWER' => 3) }
    assert_equal "invalid locals key: \"ANSWER\" (keys must be variable names)", err.message
    assert_equal "1 + 2 = 3", inst.render(Object.new, '_answer' => 3)
  end

  it "#compiled_method should return UnboundMethod for given local keys and scope class" do
    inst = _SourceGeneratingMockTemplate.new { |t| 'Hey' }
    m = inst.compiled_method([], Object)
    assert_kind_of UnboundMethod, m
    o = Object.new
    o.define_singleton_method(:x, m)
    assert_equal 'Hey', o.x({})
    assert_same m, inst.compiled_method([], Object)
    m1 = inst.compiled_method([:a], Object)
    m2 = inst.compiled_method([], Array)
    refute_same m, m1
    refute_same m, m2
    o.define_singleton_method(:y, m1)
    assert_equal 'Hey', o.y(a: 1)
    ary = []
    ary.define_singleton_method(:z, m2)
    assert_equal 'Hey', ary.z({})
  end

  it "template_source with nil locals" do
    inst = _SourceGeneratingMockTemplate.new { |t| 'Hey' }
    assert_equal 'Hey', inst.render(Object.new, nil)
    assert inst.prepared?
  end

  it "template_source with locals including 'locals'" do
    # Skip in CI on JRuby 9.1/9.2, as CI fails even though tests pass locally with these
    # JRuby versions.
    skip if defined?(JRUBY_VERSION) && JRUBY_VERSION < '9.3' && ENV['COFFEE_SCRIPT'] == 'use'

    # Ensure that a locals hash value named `locals` doesn't clobber the ability to assign other
    # locals that follow it in sorted order
    inst = _SourceGeneratingMockTemplate.new { |t| 'Hey #{name}!' }
    assert_equal "Hey Jane!", inst.render(Object.new, :locals => [], :name => 'Jane')
    assert inst.prepared?
  end

  it "template with nil compiled_path" do
    inst = _SourceGeneratingMockTemplate.new { |t| 'Hey' }
    inst.compiled_path = nil
    assert_nil inst.compiled_path
  end

  it "template with compiled_path" do
    Dir.mktmpdir('tilt') do |dir|
      base = File.join(dir, 'template')
      inst = _SourceGeneratingMockTemplate.new { |t| 'Hey' }
      inst.compiled_path = base

      tempfile = "#{base}.rb"
      assert_equal false, File.file?(tempfile)
      assert_equal 'Hey', inst.render
      assert_equal true, File.file?(tempfile)
      assert_match(/\Aclass Object/, File.read(tempfile))

      tempfile = "#{base}-1.rb"
      assert_equal false, File.file?(tempfile)
      assert_equal 'Hey', inst.render("")
      assert_equal true, File.file?(tempfile)
      assert_match(/\Aclass String/, File.read(tempfile))

      tempfile = "#{base}-2.rb"
      assert_equal false, File.file?(tempfile)
      assert_equal 'Hey', inst.render(Tilt::Mapping.new)
      assert_equal true, File.file?(tempfile)
      assert_match(/\Aclass Tilt::Mapping/, File.read(tempfile))
    end
  end

  it "template with compiled_path and with anonymous scope_class" do
    Dir.mktmpdir('tilt') do |dir|
      base = File.join(dir, 'template')
      inst = _SourceGeneratingMockTemplate.new { |t| 'Hey' }
      inst.compiled_path = base

      message = nil
      inst.define_singleton_method(:warn) { |msg| message = msg }
      scope_class = Class.new
      assert_equal 'Hey', inst.render(scope_class.new)
      assert_equal "compiled_path (#{base.inspect}) ignored on template with anonymous scope_class (#{scope_class.inspect})", message
      assert_equal [], Dir["#{dir}/*"]
    end
  end

  it "template with compiled_path with locals" do
    Dir.mktmpdir('tilt') do |dir|
      base = File.join(dir, 'template')
      inst = _SourceGeneratingMockTemplate.new { |t| 'Hey #{defined?(a)} #{defined?(b)}' }
      inst.compiled_path = base + '.rb'

      tempfile = "#{base}.rb"
      assert_equal false, File.file?(tempfile)
      assert_equal 'Hey local-variable ', inst.render(Object.new, 'a' => 1)
      content = File.read(tempfile)
      assert_match(/\Aclass Object/, content)
      assert_includes(content, "\na = locals[\"a\"]\n")

      tempfile = "#{base}-1.rb"
      assert_equal false, File.file?(tempfile)
      assert_equal 'Hey local-variable local-variable', inst.render(Object.new, 'b' => 1, 'a' => 1)
      content = File.read(tempfile)
      assert_match(/\Aclass Object/, content)
      assert_includes(content, "\na = locals[\"a\"]\nb = locals[\"b\"]\n")
    end
  end

  _CustomGeneratingMockTemplate = Class.new(_PreparingMockTemplate) do
    def precompiled_template(locals)
      data
    end

    def precompiled_preamble(locals)
      options.fetch(:preamble)
    end

    def precompiled_postamble(locals)
      options.fetch(:postamble)
    end
  end

  it "supports pre/postamble" do
    inst = _CustomGeneratingMockTemplate.new(
      :preamble => 'buf = []',
      :postamble => 'buf.join'
    ) { 'buf << 1' }

    assert_equal "1", inst.render
  end

  _Person = Class.new do
    self::CONSTANT = "Bob"

    attr_accessor :name
    def initialize(name)
      @name = name
    end
  end

  it "template_source with an object scope" do
    inst = _SourceGeneratingMockTemplate.new { |t| 'Hey #{@name}!' }
    scope = _Person.new('Joe')
    assert_equal "Hey Joe!", inst.render(scope)
  end

  it "template_source with a block for yield" do
    inst = _SourceGeneratingMockTemplate.new { |t| 'Hey #{yield}!' }
    assert_equal "Hey Joe!", inst.render(Object.new){ 'Joe' }
  end

  it "template which accesses a constant" do
    inst = _SourceGeneratingMockTemplate.new { |t| 'Hey #{CONSTANT}!' }
    assert_equal "Hey Bob!", inst.render(_Person.new("Joe"))
  end

  it "template which accesses a constant using scope class" do
    inst = _SourceGeneratingMockTemplate.new { |t| 'Hey #{CONSTANT}!' }
    assert_equal "Hey Bob!", inst.render(_Person)
  end

  _BasicPerson = Class.new(BasicObject) do
    self::CONSTANT = "Bob"

    attr_accessor :name
    def initialize(name)
      @name = name
    end
  end

  it "template_source with an BasicObject scope" do
    inst = _SourceGeneratingMockTemplate.new { |t| 'Hey #{@name}!' }
    scope = _BasicPerson.new('Joe')
    assert_equal "Hey Joe!", inst.render(scope)
  end

  it "template_source with a block for yield using BasicObject instance" do
    inst = _SourceGeneratingMockTemplate.new { |t| 'Hey #{yield}!' }
    assert_equal "Hey Joe!", inst.render(BasicObject.new){ 'Joe' }
  end

  it "template which accesses a BasicObject constant" do
    inst = _SourceGeneratingMockTemplate.new { |t| 'Hey #{CONSTANT}!' }
    assert_equal "Hey Bob!", inst.render(_BasicPerson.new("Joe"))
  end

  it "template which accesses a constant using BasicObject scope class" do
    inst = _SourceGeneratingMockTemplate.new { |t| 'Hey #{CONSTANT}!' }
    assert_equal "Hey Bob!", inst.render(_BasicPerson)
  end

  deprecated "populates Tilt.current_template during rendering" do
    inst = _SourceGeneratingMockTemplate.new { '#{$inst = Tilt.current_template}' }
    inst.render
    assert_equal inst, $inst
    assert_nil Tilt.current_template
  end

  deprecated "populates Tilt.current_template in nested rendering" do
    inst1 = _SourceGeneratingMockTemplate.new { '#{$inst.render; $inst1 = Tilt.current_template}' }
    inst2 = _SourceGeneratingMockTemplate.new { '#{$inst2 = Tilt.current_template}' }
    $inst = inst2
    inst1.render
    assert_equal inst1, $inst1
    assert_equal inst2, $inst2
    assert_nil Tilt.current_template
  end

  if RUBY_VERSION >= '2.3'
    _FrozenStringMockTemplate = Class.new(_PreparingMockTemplate) do
      def freeze_string_literals?
        true
      end
      def precompiled_template(locals)
        "'bar'"
      end
    end

    it "uses frozen literal strings if freeze_literal_strings? is true" do
      inst = _FrozenStringMockTemplate.new{|d| 'a'}
      assert_equal "bar", inst.render
      assert_equal true, inst.render.frozen?
      assert inst.prepared?
    end
  end
end

  ##
  # Encodings
describe "tilt/template (encoding)" do
  _DynamicMockTemplate = Class.new(_MockTemplate) do
    def precompiled_template(locals)
      options[:code]
    end
  end

  _UTF8Template = Class.new(_MockTemplate) do
    def default_encoding
      Encoding::UTF_8
    end
  end

  before do
    @file = Tempfile.open('template')
    @file.puts "stuff"
    @file.close
    @template = @file.path
  end

  after do
    @file.delete
  end

  it "reading from file assumes default external encoding" do
    with_default_encoding('Big5') do
      inst = _MockTemplate.new(@template)
      assert_equal 'Big5', inst.data.encoding.to_s
    end
  end

  it "reading from file with a :default_encoding overrides default external" do
    with_default_encoding('Big5') do
      inst = _MockTemplate.new(@template, :default_encoding => 'GBK')
      assert_equal 'GBK', inst.data.encoding.to_s
    end
  end

  it "reading from file with default_internal set does no transcoding" do
    begin
      silence{Encoding.default_internal = 'utf-8'}
      with_default_encoding('Big5') do
        inst = _MockTemplate.new(@template)
        assert_equal 'Big5', inst.data.encoding.to_s
      end
    ensure
      silence{Encoding.default_internal = nil}
    end
  end

  it "using provided template data verbatim when given as string" do
    with_default_encoding('Big5') do
      inst = _MockTemplate.new(@template) { "blah".force_encoding('GBK') }
      assert_equal 'GBK', inst.data.encoding.to_s
    end
  end

  it "uses the template from the generated source code" do
    with_utf8_default_encoding do
      tmpl = "ふが"
      code = tmpl.inspect.encode('Shift_JIS')
      inst = _DynamicMockTemplate.new(:code => code) { '' }
      res = inst.render
      assert_equal 'Shift_JIS', res.encoding.to_s
      assert_equal tmpl, res.encode(tmpl.encoding)
    end
  end

  it "uses the magic comment from the generated source code when generated source code is frozen" do
    with_utf8_default_encoding do
      tmpl = "ふが"
      code = ("# coding: Shift_JIS\n" + tmpl.inspect).encode('Shift_JIS')
      # Set it to an incorrect encoding
      code.force_encoding('UTF-8')
      code.freeze

      inst = _DynamicMockTemplate.new(:code => code) { '' }
      res = inst.render
      assert_equal 'Shift_JIS', res.encoding.to_s
      assert_equal tmpl, res.encode(tmpl.encoding)
    end
  end

  it "uses the magic comment from the generated source code" do
    with_utf8_default_encoding do
      tmpl = "ふが"
      code = ("# coding: Shift_JIS\n" + tmpl.inspect).encode('Shift_JIS')
      # Set it to an incorrect encoding
      code.force_encoding('UTF-8')

      inst = _DynamicMockTemplate.new(:code => code) { '' }
      res = inst.render
      assert_equal 'Shift_JIS', res.encoding.to_s
      assert_equal tmpl, res.encode(tmpl.encoding)
    end
  end

  it "uses compiled template encoding if :skip_compiled_encoding_detection is true" do
    with_utf8_default_encoding do
      tmpl = 'x'
      code = ("# coding: UTF-8\n" + tmpl.inspect).encode('UTF-8')
      # Set it to an incorrect encoding
      code.force_encoding('US-ASCII')

      inst = _DynamicMockTemplate.new(:code => code, :skip_compiled_encoding_detection=>true) { '' }
      res = inst.render
      assert_equal 'US-ASCII', res.encoding.to_s
      assert_equal tmpl, res.encode(tmpl.encoding)
    end
  end

  it "uses #default_encoding instead of default_external" do
    with_default_encoding('Big5') do
      inst = _UTF8Template.new(@template)
      assert_equal 'UTF-8', inst.data.encoding.to_s
    end
  end

  it "uses #default_encoding instead of current encoding" do
    tmpl = "".force_encoding('Big5')
    inst = _UTF8Template.new(@template) { tmpl }
    assert_equal 'UTF-8', inst.data.encoding.to_s
  end

  it "raises error if the encoding is not valid" do
    assert_raises(Encoding::InvalidByteSequenceError) do
      _UTF8Template.new(@template) { "\xe4" }
    end
  end

  it "StaticTemplate#compiled_method raise NotImplementedError" do
    c = Tilt::StaticTemplate.subclass{data}
    t = c.new{''}
    assert_raises(NotImplementedError) do
      t.compiled_method([], Object)
    end
  end
end
