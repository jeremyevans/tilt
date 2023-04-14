require_relative 'test_helper'

describe 'tilt' do
  _MockTemplate = Class.new do
    attr_reader :args, :block
    def initialize(*args, &block)
      @args = args
      @block = block
    end
  end

  after do
    Tilt.default_mapping.unregister('mock')
  end

  it "registering template implementation classes by file extension" do
    Tilt.register(_MockTemplate, 'mock')
  end

  it "an extension is registered if explicit handle is found" do
    Tilt.register(_MockTemplate, 'mock')
    assert Tilt.registered?('mock')
  end

  it "registering template classes by symbol file extension" do
    Tilt.register(_MockTemplate, :mock)
  end

  it "registering template classes with prefer" do
    Tilt.prefer(_MockTemplate, :mock)
  end

  it "looking up template classes by exact file extension" do
    Tilt.register(_MockTemplate, 'mock')
    impl = Tilt['mock']
    assert_equal _MockTemplate, impl
  end

  it "should have working template_for" do
    Tilt.register(_MockTemplate, 'mock')
    assert_equal _MockTemplate, Tilt.template_for('mock')
  end

  it "should have working templates_for" do
    Tilt.register(_MockTemplate, 'mock')
    assert_equal [_MockTemplate], Tilt.templates_for('mock')
  end

  it "looking up template classes by implicit file extension" do
    Tilt.register(_MockTemplate, 'mock')
    impl = Tilt['.mock']
    assert_equal _MockTemplate, impl
  end

  it "looking up template classes with multiple file extensions" do
    Tilt.register(_MockTemplate, 'mock')
    impl = Tilt['index.html.mock']
    assert_equal _MockTemplate, impl
  end

  it "looking up template classes by file name" do
    Tilt.register(_MockTemplate, 'mock')
    impl = Tilt['templates/test.mock']
    assert_equal _MockTemplate, impl
  end

  it "looking up non-existant template class" do
    assert_nil Tilt['none']
  end

  it "creating new template instance with a filename" do
    Tilt.register(_MockTemplate, 'mock')
    template = Tilt.new('foo.mock', 1, :key => 'val') { 'Hello World!' }
    assert_equal ['foo.mock', 1, {:key => 'val'}], template.args
    assert_equal 'Hello World!', template.block.call
  end
end

describe 'Tilt' do
  _Stub = Class.new
  _Stub2 = Class.new

  before do
    @default_mapping = Tilt.default_mapping
    frozen = @frozen = []

    Tilt.class_eval do
      define_singleton_method(:freeze){frozen << self}
      @default_mapping = Tilt::Mapping.new
      register(_Stub, 'foo', 'bar')
      register(_Stub2, 'foo', 'baz')
      register_lazy(:StringTemplate, 'str')
    end
  end

  after do
    Tilt.singleton_class.send(:remove_method, :freeze)
    mod = Tilt.singleton_class.ancestors.first
    mod.send(:remove_method, :lazy_map)
    mod.send(:remove_method, :register)
    mod.send(:remove_method, :prefer)
    mod.send(:remove_method, :register_lazy)
    mod.send(:remove_method, :register_pipeline)
    Tilt.instance_variable_set(:@default_mapping,  @default_mapping)
  end

  it ".finalize! switches to a finalized mapping" do
    assert_equal [], @frozen
    refute Tilt.default_mapping.frozen?

    Tilt.finalize!
    assert Tilt.default_mapping.frozen?
    assert_equal [Tilt], @frozen
    assert_equal _Stub2, Tilt['foo']
    assert_equal _Stub, Tilt['bar']
    assert_nil Tilt['str']

    assert_raises(RuntimeError){Tilt.lazy_map}
    assert_raises(RuntimeError){Tilt.register(Class.new, 'mock')}
    assert_raises(RuntimeError){Tilt.prefer(Class.new, 'mock')}
    assert_raises(RuntimeError){Tilt.register_lazy(:StringTemplate, 'str2')}
    assert_raises(RuntimeError){Tilt.register_pipeline('str.erb')}
  end
end
