require_relative 'test_helper'

checked_describe 'tilt/commonmarker' do
  it "preparing and evaluating templates on #render" do
    template = Tilt::CommonMarkerTemplate.new { |t| "# Hello World!" }
    res = template.render
    assert_includes ["<h1>Hello World!</h1>\n", "<h1><a href=\"#hello-world\" aria-hidden=\"true\" class=\"anchor\" id=\"hello-world\"></a>Hello World!</h1>\n"], template.render
  end

  it "can be rendered more than once" do
    template = Tilt::CommonMarkerTemplate.new { |t| "# Hello World!" }
    3.times do
      res = template.render
      assert_includes ["<h1>Hello World!</h1>\n", "<h1><a href=\"#hello-world\" aria-hidden=\"true\" class=\"anchor\" id=\"hello-world\"></a>Hello World!</h1>\n"], template.render
    end
  end

  it "smartypants when :smartypants is set" do
    template = Tilt::CommonMarkerTemplate.new(:smartypants => true) do |t|
      "OKAY -- 'Smarty Pants'"
    end
    assert_match('<p>OKAY – ‘Smarty Pants’</p>', template.render)
  end

  it 'Renders unsafe HTML when :UNSAFE is set' do
    template = Tilt::CommonMarkerTemplate.new(UNSAFE: true) do |_t|
      <<MARKDOWN
<div class="alert alert-info full-width">
<h5 class="card-title">TL;DR</h5>
<p>This is an unsafe HTML block</p>
</div>

And then some **other** Markdown
MARKDOWN
    end

    expected = <<EXPECTED_HTML
<div class="alert alert-info full-width">
<h5 class="card-title">TL;DR</h5>
<p>This is an unsafe HTML block</p>
</div>
<p>And then some <strong>other</strong> Markdown</p>
EXPECTED_HTML

    assert_match(expected, template.render)
  end

  it "sets allows_script metadata set to false" do
    assert_equal false, Tilt::CommonMarkerTemplate.new { |t| "# Hello World!" }.metadata[:allows_script]
  end

  if defined?(::Commonmarker)
    it "render unsafe HTML with pre version's option name" do
      template = Tilt::CommonMarkerTemplate.new(UNSAFE: true) do |_t|
        <<MARKDOWN
<div class="alert alert-info full-width">
<h5 class="card-title">TL;DR</h5>
<p>This is an unsafe HTML block</p>
</div>

And then some **other** Markdown
MARKDOWN
      end

      expected = <<EXPECTED_HTML
<div class="alert alert-info full-width">
<h5 class="card-title">TL;DR</h5>
<p>This is an unsafe HTML block</p>
</div>
<p>And then some <strong>other</strong> Markdown</p>
EXPECTED_HTML

      assert_match(expected, template.render)
    end

    it "smartypants when :smartypants is set (pre version's option name)" do
      template = Tilt::CommonMarkerTemplate.new(:smartypants => true) do |t|
        "OKAY -- 'Smarty Pants'"
      end
      assert_match('<p>OKAY – ‘Smarty Pants’</p>', template.render)
    end

    it "render markdown with custom prefixed-header id" do
      template = Tilt::CommonMarkerTemplate.new(header_ids: "prefix-") do |t|
        "# Foo"
      end
      expected = <<HTML
<h1><a href="#foo" aria-hidden="true" class="anchor" id="prefix-foo"></a>Foo</h1>
HTML
      assert_match(expected, template.render)
    end
  end
end
