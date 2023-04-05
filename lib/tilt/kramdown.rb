require_relative 'template'
require 'kramdown'

module Tilt
  # Kramdown Markdown implementation. See: https://kramdown.gettalong.org/
  class KramdownTemplate < Template
    DUMB_QUOTES = [39, 39, 34, 34].freeze

    def prepare
      unless options[:smartypants]
        # dup as Krawmdown modifies the passed option with map!
        options[:smart_quotes] = DUMB_QUOTES.dup
      end

      @engine = Kramdown::Document.new(data, options)
      @output = nil
    end

    def evaluate(scope, locals, &block)
      @output ||= @engine.to_html
    end

    def allows_script?
      false
    end
  end
end
