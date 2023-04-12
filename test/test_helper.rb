require_relative 'coverage_helper'

$LOAD_PATH << File.expand_path('../../lib', __FILE__)

require_relative  '../lib/tilt'

ENV['MT_NO_PLUGINS'] = '1' # Work around stupid autoloading of plugins
require 'minitest/autorun'
require 'minitest/mock'

if $VERBOSE
  begin
    require 'warning'
  rescue LoadError
  else
    Warning.ignore(%r{lib/wikicloth/extensions/|lib/pdf/reader/font.rb|lib/maruku/|lib/creole/parser.rb})
  end
end

FrozenError = RuntimeError unless defined?(FrozenError)

def self.checked_require(lib)
  require lib
rescue LoadError => e
  warn "skipping tests of #{lib}: #{e.class}: #{e.message}"
else
  yield
end

def self.checked_describe(lib, &block)
  checked_require lib do
    describe(lib, &block)
  end
end


class Minitest::Spec
  # Returns true if line numbers are reported incorrectly in heredocs.
  def heredoc_line_number_bug?
    # https://github.com/jruby/jruby/issues/7272
    RUBY_PLATFORM == "java"
  end

  def with_default_encoding(encoding)
    prev = Encoding.default_external

    begin
      silence{Encoding.default_external = encoding}

      yield
    ensure
      silence{Encoding.default_external = prev}
    end
  end

  def with_utf8_default_encoding(&block)
    with_default_encoding('UTF-8', &block)
  end

  def self.deprecated(*a, &block)
    it(*a){silence{instance_exec(&block)}}
  end

  def silence
    verbose, $VERBOSE = $VERBOSE, nil
    yield
  ensure
    $VERBOSE = verbose
  end
end
