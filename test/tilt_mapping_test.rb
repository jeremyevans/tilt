require_relative 'test_helper'
require 'tilt/string'

describe 'Tilt::Mapping' do
  _Stub = Class.new
  _Stub2 = Class.new

  before do
    @mapping = Tilt::Mapping.new
  end

  it "registered?" do
    @mapping.register(_Stub, 'foo', 'bar')
    assert @mapping.registered?('foo')
    assert @mapping.registered?('bar')
    refute @mapping.registered?('baz')
  end

  it "unregister" do
    @mapping.register(_Stub, 'foo', 'bar', 'baz')
    @mapping.unregister('baz')
    assert @mapping.registered?('foo')
    assert @mapping.registered?('bar')
    refute @mapping.registered?('baz')
  end

  it "lookups on registered" do
    @mapping.register(_Stub, 'foo', 'bar')
    assert_equal _Stub, @mapping['foo']
    assert_equal _Stub, @mapping['bar']
    assert_equal _Stub, @mapping['hello.foo']
    assert_nil @mapping['foo.baz']
  end

  it "can be dup'd" do
    @mapping.register(_Stub, 'foo')
    other = @mapping.dup
    assert other.registered?('foo')

    # @mapping doesn't leak to other
    @mapping.register(_Stub, 'bar')
    refute other.registered?('bar')

    # other doesn't leak to @mapping
    other.register(_Stub, 'baz')
    refute @mapping.registered?('baz')
  end

  it "#extensions_for" do
    @mapping.register(_Stub, 'foo', 'bar')
    assert_equal ['foo', 'bar'].sort, @mapping.extensions_for(_Stub).sort
  end

  it "supports old-style #register" do
    @mapping.register('foo', _Stub)
    assert_equal _Stub, @mapping['foo']
  end

  it "#new raises if no template engine found" do
    assert_raises(RuntimeError) do
      @mapping.new('foo.nonexistant')
    end
  end

  it "#[] raises if template engine recognized but cannot be loaded" do
    @mapping.register_lazy :NonExistantTemplate,    'tilt/nonexistant_template',    'test-nonexist'
    assert_raises(LoadError) do
      @mapping['foo.test-nonexist']
    end
  end

  describe "lazy with one template class" do
    before do
      @mapping.register_lazy('MyTemplate', 'my_template', 'mt')
      @loaded_before = $LOADED_FEATURES.dup
    end

    after do
      Object.send :remove_const, :MyTemplate if defined? ::MyTemplate
      $LOADED_FEATURES.replace(@loaded_before)
    end

    it "registered?" do
      assert @mapping.registered?('mt')
    end

    it "unregister" do
      @mapping.unregister('mt')
      refute @mapping.registered?('mt')
    end

    it "#extensions_for" do
      assert_equal ['mt'], @mapping.extensions_for('MyTemplate')
    end

    it "basic lookup" do
      req = proc do |file|
        assert_equal 'my_template', file
        class ::MyTemplate; end
        true
      end

      @mapping.stub :require, req do
        klass = @mapping['hello.mt']
        assert_equal ::MyTemplate, klass
      end
    end

    it "doesn't require when template class is present" do
      class ::MyTemplate; end

      req = proc do |file|
        flunk "#require shouldn't be called"
      end

      @mapping.stub :require, req do
        klass = @mapping['hello.mt']
        assert_equal ::MyTemplate, klass
      end
    end

    it "doesn't require when the template class is autoloaded, and then defined" do
      $LOAD_PATH << __dir__
      begin
        Object.autoload :MyTemplate, 'mytemplate'
        did_load = require 'mytemplate'
      ensure
        $LOAD_PATH.delete(__dir__)
      end
      assert did_load, "mytemplate wasn't freshly required"

      req = proc do |file|
        flunk "#require shouldn't be called"
      end

      @mapping.stub :require, req do
        klass = @mapping['hello.mt']
        assert_equal ::MyTemplate, klass
      end
    end

    it "raises NameError when the class name is defined" do
      req = proc do |file|
        # do nothing
      end

      @mapping.stub :require, req do
        assert_raises(NameError) do
          @mapping['hello.mt']
        end
      end
    end
  end

  describe "lazy with two template classes" do
    before do
      @mapping.register_lazy('MyTemplate1', 'my_template1', 'mt')
      @mapping.register_lazy('MyTemplate2', 'my_template2', 'mt')
    end

    after do
      Object.send :remove_const, :MyTemplate1 if defined? ::MyTemplate1
      Object.send :remove_const, :MyTemplate2 if defined? ::MyTemplate2
    end

    it "registered?" do
      assert @mapping.registered?('mt')
    end

    it "only attempt to load the last template" do
      req = proc do |file|
        assert_equal 'my_template2', file
        class ::MyTemplate2; end
        true
      end

      @mapping.stub :require, req do
        klass = @mapping['hello.mt']
        assert_equal ::MyTemplate2, klass
      end
    end

    it "uses the first template if it's present" do
      class ::MyTemplate1; end

      req = proc do |file|
        flunk
      end

      @mapping.stub :require, req do
        klass = @mapping['hello.mt']
        assert_equal ::MyTemplate1, klass
      end
    end

    it "falls back when LoadError is thrown" do
      req = proc do |file|
        raise LoadError unless file == 'my_template1'
        class ::MyTemplate1; end
        true
      end

      @mapping.stub :require, req do
        klass = @mapping['hello.mt']
        assert_equal ::MyTemplate1, klass
      end
    end

    it "raises the first LoadError when everything fails" do
      req = proc do |file|
        raise LoadError, file
      end

      @mapping.stub :require, req do
        err = assert_raises(LoadError) do
          @mapping['hello.mt']
        end

        assert_equal 'my_template2', err.message
      end
    end

    it "handles autoloaded constants" do
      Object.autoload :MyTemplate2, 'my_template2'
      class ::MyTemplate1; end

      assert_equal MyTemplate1, @mapping['hello.mt']
    end
  end

  it "raises NameError on invalid class name" do
    @mapping.register_lazy '#foo', 'my_template', 'mt'

    req = proc do |file|
      # do nothing
    end

    @mapping.stub :require, req do
      assert_raises(NameError) do
        @mapping['hello.mt']
      end
    end
  end

  describe "#templates_for" do
    before do
      @mapping.register _Stub, 'a'
      @mapping.register _Stub2, 'b'
    end

    it "handles multiple engines" do
      assert_equal [_Stub2, _Stub], @mapping.templates_for('hello/world.a.b')
    end
  end
end

describe 'Tilt::FinalizedMapping' do
  next if defined?(JRUBY_VERSION) && JRUBY_VERSION < '9.2'

  _Stub = Class.new
  _Stub2 = Class.new

  before do
    mapping = Tilt::Mapping.new
    mapping.register(_Stub, 'foo', 'bar')
    mapping.register(_Stub2, 'foo', 'baz')
    mapping.register_lazy(:NonExistant, 'tilt/nonexistant', 'str')
    mapping.register_lazy(:StringTemplate, 'tilt/string', 'string')
    @mapping = mapping.finalized
  end

  it "does not allow modification" do
    refute @mapping.respond_to?(:register)
    refute @mapping.respond_to?(:register_lazy)
    refute @mapping.respond_to?(:unregister)
    refute @mapping.respond_to?(:register_pipeline)
    assert @mapping.frozen?
  end

  it "#registered?" do
    assert @mapping.registered?('foo')
    assert @mapping.registered?('bar')
    assert @mapping.registered?('baz')
    assert @mapping.registered?('string')
    refute @mapping.registered?('str')
  end

  it "#[]" do
    assert_equal _Stub2, @mapping['x.foo']
    assert_equal _Stub, @mapping['x.bar']
    assert_equal _Stub2, @mapping['x.baz']
    assert_nil @mapping['x.str']
    assert_equal Tilt::StringTemplate, @mapping['x.string']
  end

  it "#templates_for" do
    assert_equal [_Stub, _Stub2], @mapping.templates_for('x.foo.bar')
    assert_equal [_Stub], @mapping.templates_for('x.bar')
    assert_equal [_Stub2], @mapping.templates_for('x.baz')
    assert_equal [], @mapping.templates_for('x.str')
    assert_equal [Tilt::StringTemplate], @mapping.templates_for('x.string')
  end

  it "#extensions_for" do
    assert_equal ['bar'], @mapping.extensions_for(_Stub)
    assert_equal ['foo', 'baz'], @mapping.extensions_for(_Stub2)
    assert_equal ['string'], @mapping.extensions_for(Tilt::StringTemplate)
    assert_equal [], @mapping.extensions_for(Object)
  end

  it "#clone" do
    m = @mapping.clone
    assert m.frozen?
    assert_equal _Stub2, m['x.foo']
    assert_equal Tilt::StringTemplate, m['x.string']
    assert_nil m['x.str']
  end

  it "#dup" do
    m = @mapping.dup
    assert m.frozen?
    assert_equal _Stub2, m['x.foo']
    assert_equal Tilt::StringTemplate, m['x.string']
    assert_nil m['x.str']
  end
end
