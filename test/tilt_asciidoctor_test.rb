require_relative 'test_helper'

checked_describe 'tilt/asciidoc' do
  html5_output = "<div class=\"sect1\"><h2 id=\"_hello_world\">Hello World!</h2><div class=\"sectionbody\"></div></div>"
  docbook5_output = "<section xml:id=\"_hello_world\"><title>Hello World!</title></section>"

  def strip_space(str)
    str.gsub(/>\s+</, '><').strip
  end

  it "registered for '.ad' files" do
    assert_equal Tilt::AsciidoctorTemplate, Tilt['ad']
  end

  it "registered for '.adoc' files" do
    assert_equal Tilt::AsciidoctorTemplate, Tilt['adoc']
  end

  it "registered for '.asciidoc' files" do
    assert_equal Tilt::AsciidoctorTemplate, Tilt['asciidoc']
  end

  it "#extensions_for returns a unique list of extensions" do
    Tilt.default_mapping.extensions_for(Tilt::AsciidoctorTemplate).each do |ext|
      Tilt[ext]
    end
    assert_equal ['ad', 'adoc', 'asciidoc'], Tilt.default_mapping.extensions_for(Tilt::AsciidoctorTemplate).sort
  end

  it "preparing and evaluating html5 templates on #render" do
    template = Tilt::AsciidoctorTemplate.new(:attributes => {"backend" => 'html5'}) { |t| "== Hello World!" } 
    3.times { assert_equal html5_output, strip_space(template.render) }
  end

  it "preparing and evaluating docbook 5 templates on #render" do
    template = Tilt::AsciidoctorTemplate.new(:attributes => {"backend" => 'docbook5'}) { |t| "== Hello World!" }
    assert_equal docbook5_output, strip_space(template.render)
  end

  it "supports header_footer: true option" do
    template = Tilt::AsciidoctorTemplate.new(:header_footer=>true) { |t| "== Hello World!" }
    output = strip_space(template.render)
    assert_includes output, html5_output
    assert_match(/\A<!DOCTYPE html>.*<\/html>\z/m, output)
  end

  it "sets allows_script metadata set to false" do
    assert_equal false, Tilt::AsciidoctorTemplate.new{ |t| "" }.metadata[:allows_script]
  end
end
