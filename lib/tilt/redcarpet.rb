require_relative 'template'
require 'redcarpet'

module Tilt
  class RedcarpetTemplate < Template
    self.default_mime_type = 'text/html'

    def allows_script?
      false
    end

    ALIAS = {
      :escape_html => :filter_html,
      :smartypants => :smart
    }

  # :nocov:
  unless defined? ::Redcarpet::Render and defined? ::Redcarpet::Markdown
    # Redcarpet 1.x
    warn "Tilt support for RedCarpet 1.x is deprecated and will be removed in Tilt 2.3", uplevel: 1

    FLAGS = [:smart, :filter_html, :smartypants, :escape_html]

    def flags
      FLAGS.select { |flag| options[flag] }.map { |flag| ALIAS[flag] || flag }
    end

    def prepare
      @engine = RedcarpetCompat.new(data, *flags)
      @output = nil
    end

    def evaluate(scope, locals, &block)
      @output ||= @engine.to_html
    end
  # :nocov:
  else
    def generate_renderer
      renderer = options.delete(:renderer) || ::Redcarpet::Render::HTML.new(options)
      return renderer unless options.delete(:smartypants)
      return renderer if renderer.is_a?(Class) && renderer <= ::Redcarpet::Render::SmartyPants

      if renderer == ::Redcarpet::Render::XHTML
        ::Redcarpet::Render::SmartyHTML.new(:xhtml => true)
      elsif renderer == ::Redcarpet::Render::HTML
        ::Redcarpet::Render::SmartyHTML
      elsif renderer.is_a? Class
        Class.new(renderer) { include ::Redcarpet::Render::SmartyPants }
      else
        renderer.extend ::Redcarpet::Render::SmartyPants
      end
    end

    def prepare
      # try to support the same aliases
      ALIAS.each do |opt, aka|
        if options.key?(aka) || !options.key?(opt)
          options[opt] = options.delete(aka)
        end
      end

      # only raise an exception if someone is trying to enable :escape_html
      options.delete(:escape_html) unless options[:escape_html]

      @engine = ::Redcarpet::Markdown.new(generate_renderer, options)
      @output = nil
    end

    def evaluate(scope, locals, &block)
      @output ||= @engine.render(data)
    end
  end

  end
end
