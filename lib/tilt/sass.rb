require_relative 'template'

module Tilt
  # Sass template implementation for generating CSS. See: https://sass-lang.com/
  #
  # Sass templates do not support object scopes, locals, or yield.
  class SassTemplate < Template
    self.default_mime_type = 'text/css'

    def allows_script?
      false
    end

    begin
      require 'sass-embedded'
    # :nocov:
      require 'uri'
      Engine = nil

      def evaluate(scope, locals, &block)
        @output ||= ::Sass.compile_string(data, **sass_options).css
      end

      private

      def sass_options
        path = File.absolute_path(eval_file)
        path = '/' + path unless path.start_with?('/')
        eval_file_url = ::URI::File.build([nil, ::URI::DEFAULT_PARSER.escape(path)]).to_s
        options.merge(:url => eval_file_url, :syntax => :indented)
      end
    rescue LoadError => err
      begin
        require 'sassc'
        Engine = ::SassC::Engine
      rescue LoadError
        begin
          require 'sass'
          Engine = ::Sass::Engine
        rescue LoadError
          raise err
        end
      end

      def prepare
        @engine = Engine.new(data, sass_options)
      end

      def evaluate(scope, locals, &block)
        @output ||= @engine.render
      end

      private

      def sass_options
        options.merge(:filename => eval_file, :line => line, :syntax => :sass)
      end
    # :nocov:
    end
  end

  class ScssTemplate < SassTemplate
    self.default_mime_type = 'text/css'

    private

    def sass_options
      options = super
      # Mutation is safe here, because the superclass method always
      # returns new hash.
      options[:syntax] = :scss
      options
    end
  end
end
