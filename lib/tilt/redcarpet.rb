# frozen_string_literal: true
require_relative 'template'
require 'redcarpet'

aliases = {:escape_html => :filter_html, :smartypants => :smart}.freeze

# :nocov:
unless defined? ::Redcarpet::Render and defined? ::Redcarpet::Markdown
  # Redcarpet 1.x
  warn "Tilt support for RedCarpet 1.x is deprecated and will be removed in Tilt 2.3", uplevel: 1
  _flags = [:smart, :filter_html, :smartypants, :escape_html]

  Tilt::RedcarpetTemplate = Tilt::StaticTemplate.subclass do
    flags = _flags.select { |flag| @options[flag] }.map! { |flag| aliases[flag] || flag }
    RedcarpetCompat.new(@data, *flags).to_html
  end
# :nocov:
else
  Tilt::RedcarpetTemplate = Tilt::StaticTemplate.subclass do
    aliases.each do |opt, aka|
      if options.key?(aka) || !@options.key?(opt)
        @options[opt] = @options.delete(aka)
      end
    end

    # only raise an exception if someone is trying to enable :escape_html
    @options.delete(:escape_html) unless @options[:escape_html]

    renderer = @options.delete(:renderer) || ::Redcarpet::Render::HTML.new(@options)
    if options.delete(:smartypants) && !(renderer.is_a?(Class) && renderer <= ::Redcarpet::Render::SmartyPants)
      renderer = if renderer == ::Redcarpet::Render::XHTML
        ::Redcarpet::Render::SmartyHTML.new(:xhtml => true)
      elsif renderer == ::Redcarpet::Render::HTML
        ::Redcarpet::Render::SmartyHTML
      elsif renderer.is_a? Class
        Class.new(renderer) { include ::Redcarpet::Render::SmartyPants }
      else
        renderer.extend ::Redcarpet::Render::SmartyPants
      end
    end

    Redcarpet::Markdown.new(renderer, @options).render(@data)
  end
end
