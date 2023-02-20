$LOAD_PATH << File.expand_path('../../lib', __FILE__)

require_relative  '../lib/tilt'

ENV['MT_NO_PLUGINS'] = '1' # Work around stupid autoloading of plugins
require 'minitest/autorun'
require 'minitest/mock'

FrozenError = RuntimeError unless defined?(FrozenError)

class Minitest::Spec
  # Returns true if line numbers are reported incorrectly in heredocs.
  def heredoc_line_number_bug?
    # https://github.com/jruby/jruby/issues/7272
    RUBY_PLATFORM == "java"
  end

  def with_default_encoding(encoding)
    prev = Encoding.default_external

    begin
      Encoding.default_external = encoding

      yield
    ensure
      Encoding.default_external = prev
    end
  end

  def with_utf8_default_encoding(&block)
    with_default_encoding('UTF-8', &block)
  end

  def self.deprecated(*a, &block)
    it(*a) do
      begin
        verbose, $VERBOSE = $VERBOSE, nil
        instance_exec(&block)
      ensure
        $VERBOSE = verbose
      end
    end
  end
end
