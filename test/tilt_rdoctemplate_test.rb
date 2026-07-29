require_relative 'test_helper'

checked_describe 'tilt/rdoc' do
  it "is registered for '.rdoc' files" do
    assert_equal Tilt::RDocTemplate, Tilt['test.rdoc']
  end

  it "preparing and evaluating the template with #render" do
    template = Tilt::RDocTemplate.new { |t| "= Hello World!" }
    3.times do
      result = template.render.strip
      assert_match %r(<h1), result
      assert_match %r(>Hello World!<), result
    end
  end

  it "sets allows_script metadata set to false" do
    assert_equal false, Tilt::RDocTemplate.new{|t| "= Hello World!"}.metadata[:allows_script]
  end
end
