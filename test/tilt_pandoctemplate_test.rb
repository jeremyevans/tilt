require 'test_helper'
require 'tilt'

begin
  require 'tilt/pandoc'

  class PandocTemplateTest < Minitest::Test
    test "registered below Kramdown" do
      %w[md mkd markdown].each do |ext|
        lazy = Tilt.lazy_map[ext]
        kram_idx = lazy.index { |klass, file| klass == 'Tilt::KramdownTemplate' }
        pandoc_idx = lazy.index { |klass, file| klass == 'Tilt::PandocTemplate' }
        assert pandoc_idx > kram_idx,
          "#{pandoc_idx} should be higher than #{kram_idx}"
      end
    end

    test "preparing and evaluating templates on #render" do
      template = Tilt::PandocTemplate.new { |t| "# Hello World!" }
      assert_equal "<h1 id=\"hello-world\">Hello World!</h1>", template.render.strip
    end

    test "can be rendered more than once" do
      template = Tilt::PandocTemplate.new { |t| "# Hello World!" }
      3.times { assert_equal "<h1 id=\"hello-world\">Hello World!</h1>", template.render.strip }
    end

    test "smartypants when :smartypants is set" do
      template = Tilt::PandocTemplate.new(:smartypants => true) { |t| "OKAY -- 'Smarty Pants'" }
      assert_equal "<p>OKAY – ‘Smarty Pants’</p>", template.render
    end

    test "stripping HTML when :escape_html is set" do
      skip "Couldn't find appropriate option for Pandoc, see http://stackoverflow.com/questions/37165374/pandoc-escape-html-option"
      template = Tilt::PandocTemplate.new(:escape_html => true) { |t| "HELLO <blink>WORLD</blink>" }
      assert_equal "<p>HELLO &lt;blink>WORLD&lt;/blink></p>", template.render
    end

    # Pandoc has tons of additional markdown features.
    # The test for footnotes should be see as a general representation for all of them.
    test "generates footnotes" do
      template = Tilt::PandocTemplate.new { |t| "Here is an inline note.^[Inlines notes are cool!]" }
      assert_equal "<p>Here is an inline note.<a href=\"#fn1\" class=\"footnoteRef\" id=\"fnref1\"><sup>1</sup></a></p>\n<div class=\"footnotes\">\n<hr />\n<ol>\n<li id=\"fn1\"><p>Inlines notes are cool!<a href=\"#fnref1\">↩</a></p></li>\n</ol>\n</div>", template.render.strip
    end

    describe "passing in Pandoc options" do
      test "accepts arguments with values" do
        # Table of contents isn't on by default
        template = Tilt::PandocTemplate.new { |t| "# This is a heading" }
        assert_equal "<h1 id=\"this-is-a-heading\">This is a heading</h1>", template.render

        # But it can be activated
        template = Tilt::PandocTemplate.new(id_prefix: 'test-') { |t| "# This is a heading" }
        assert_equal "<h1 id=\"test-this-is-a-heading\">This is a heading</h1>", template.render
      end

      # Arguments without value (e.g. --standalone) need to be passed as hash keys, too (simply set them to true)
      test "requires arguments without value as true values" do
        template = Tilt::PandocTemplate.new(standalone: true) { |t| "# This is a heading" }
        assert_match /^<!DOCTYPE html.*<h1 id="this-is-a-heading">This is a heading<\/h1>.*<\/html>$/m, template.render
      end
    end
  end
rescue LoadError => boom
  warn "Tilt::PandocTemplate (disabled)"
end
