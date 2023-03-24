require_relative 'template'
require 'coffee_script'

module Tilt
  # CoffeeScript template implementation. See:
  # http://coffeescript.org/
  #
  # CoffeeScript templates do not support object scopes, locals, or yield.
  class CoffeeScriptTemplate < Template
    self.default_mime_type = 'application/javascript'

    @default_bare = false
    singleton_class.attr_accessor :default_bare

    # :nocov:
    def self.default_no_wrap
      warn "#{self.class}.default_no_wrap is deprecated and will be removed in Tilt 2.3.  Switch to #{self.class}.default_bare."
      default_bare
    end

    def self.default_no_wrap=(value)
      warn "#{self.class}.default_no_wrap= is deprecated and will be removed in Tilt 2.3.  Switch to #{self.class}.default_bare=."
      self.default_bare = value
    end
    # :nocov:

    def self.literate?
      false
    end

    def prepare
      if !options.key?(:bare) and !options.key?(:no_wrap)
        options[:bare] = self.class.default_bare
      end
      options[:literate] ||= self.class.literate?
    end

    def evaluate(scope, locals, &block)
      @output ||= CoffeeScript.compile(data, options)
    end

    def allows_script?
      false
    end
  end

  class CoffeeScriptLiterateTemplate < CoffeeScriptTemplate
    @default_bare = false

    def self.literate?
      true
    end
  end
end

