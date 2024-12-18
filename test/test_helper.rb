require_relative 'coverage_helper'

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require_relative  '../lib/tilt'

ENV['MT_NO_PLUGINS'] = '1' # Work around stupid autoloading of plugins
require 'minitest/autorun'
require 'minitest/mock'

if $VERBOSE
  begin
    require 'warning'
  rescue LoadError
  else
    Warning.ignore(%r{lib/pdf/reader/font.rb|lib/creole/parser.rb|lib/commonmarker})
  end
end

FrozenError = RuntimeError unless defined?(FrozenError)

def self.checked_require(*libs)
  verbose, $VERBOSE = $VERBOSE, nil
  libs.each do |lib|
    require lib
  end
rescue LoadError => e
  $VERBOSE = verbose
  warn "skipping tests of #{libs.first}: #{e.class}: #{e.message}"
else
  $VERBOSE = verbose
  yield
end

def self.checked_describe(*libs, &block)
  checked_require(*libs) do
    describe(libs.first, &block)
  end
end

module IgnoreVerboseWarnings
  def setup
    @_verbose = $VERBOSE
    $VERBOSE = nil
  end

  def teardown
    $VERBOSE = @_verbose
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
