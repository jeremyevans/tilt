require_relative 'template'
require 'rdoc'
require 'rdoc/markup'
require 'rdoc/markup/to_html'
require 'rdoc/options'

module Tilt
  # RDoc template. See: https://github.com/ruby/rdoc
  #
  # It's suggested that your program run the following at load time when
  # using this templae engine in a threaded environment:
  #
  #   require 'rdoc'
  #   require 'rdoc/markup'
  #   require 'rdoc/markup/to_html'
  #   require 'rdoc/options'
  class RDocTemplate < Template
    self.default_mime_type = 'text/html'

    def prepare
      @engine = RDoc::Markup::ToHtml.new(RDoc::Options.new, nil).convert(data)
      @output = nil
    end

    def evaluate(scope, locals, &block)
      @output ||= @engine.to_s
    end

    def allows_script?
      false
    end
  end
end
