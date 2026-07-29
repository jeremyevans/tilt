require_relative 'test_helper'

checked_describe 'tilt/typescript' do
  before do
    @ts = "var x:number = 5"
    @js = 'var x = 5;'
  end

  it "is registered for '.ts' files" do
    assert_equal Tilt::TypeScriptTemplate, Tilt['test.ts']
  end

  it "is registered for '.tsx' files" do
    assert_equal Tilt::TypeScriptTemplate, Tilt['test.tsx']
  end

  it "compiles and evaluates the template on #render" do
    template = Tilt::TypeScriptTemplate.new { @ts }
    3.times { assert_includes template.render, @js }
  end

  it "supports source map" do
    template = Tilt::TypeScriptTemplate.new(inlineSourceMap: true)  { @ts }
    assert_includes template.render, 'sourceMappingURL'
  end

  it "skips options with nil value" do
    template = Tilt::TypeScriptTemplate.new(completely_bogus_option: nil) { @ts }
    assert_includes template.render, @js
  end

  it "supports options with string values" do
    template = Tilt::TypeScriptTemplate.new(target: 'ES5') { '() => this' }
    assert_includes template.render, 'function () { return _this; }'
    template = Tilt::TypeScriptTemplate.new(target: 'ES6') { '() => this' }
    assert_includes template.render, '() => this'
  end
end
