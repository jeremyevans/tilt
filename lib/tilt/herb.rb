# frozen_string_literal: true

# = Herb (<tt>herb</tt>, <tt>html.erb</tt>)
#
# {Herb}[https://herb-tools.dev] is an HTML-aware ERB implementation, which parses the
# HTML in the template in addition to the embedded Ruby.
#
# Herb's engine is API compatible with the Erubi engine, so all the documentation of
# {Erubi}[rdoc-ref:lib/tilt/erubi.rb] applies in addition to the following:
#
# === Differences from Erubi
#
# Herb parses the HTML in the template, and raises <tt>Herb::Engine::CompilationError</tt>
# when creating the template if the HTML is invalid (such as unclosed or mismatched tags),
# or if the embedded Ruby has invalid syntax. Erubi inspects neither the HTML nor the Ruby;
# with Erubi, invalid Ruby syntax instead raises a SyntaxError when Tilt compiles the
# template, which by default does not happen until the template is first rendered.
#
# Herb escapes interpolated values based on where they appear in the document, using a
# separate escape function for attribute values, <tt><script></tt> content, and
# <tt><style></tt> content. Erubi uses a single escape function everywhere.
#
# Herb accepts additional engine options. As with the Erubi engine options, these are
# passed through to the engine class. See
# {Herb::Engine}[https://herb-tools.dev/projects/engine] for the full list.
#
# === Usage
#
# The <tt>Tilt::HerbTemplate</tt> class is registered for all files ending in <tt>.herb</tt> or
# <tt>.html.erb</tt> by default. Unlike {Erubi}[rdoc-ref:lib/tilt/erubi.rb], it is not
# registered for <tt>.erb</tt> or <tt>.rhtml</tt>, since that would change which engine is
# used for existing templates. To use Herb for those as well, use:
#
#     Tilt.register Tilt::HerbTemplate, 'erb', 'rhtml'
#
# __NOTE:__ It's suggested that your program <tt>require 'herb'</tt> at load time when
# using this template engine within a threaded environment.
#
# === Options
#
# ==== <tt>:engine_class => Herb::Engine</tt>
#
# Allows you to specify a custom engine class to use instead of the
# default which is <tt>Herb::Engine</tt>.
#
# ==== Other
#
# Other options are passed to the constructor of the engine class.
#
# === See also
#
# * {Herb Home}[https://herb-tools.dev]
# * {Herb::Engine}[https://herb-tools.dev/projects/engine]
# * {Herb Source}[https://github.com/marcoroth/herb]
#
# === Related module
#
# * Tilt::HerbTemplate

require_relative 'template'
require 'herb'
require 'herb/engine'

module Tilt
  class HerbTemplate < Template
    def prepare
      @options[:preamble] = false
      @options[:postamble] = false
      @options[:ensure] = true

      # Unlike Erubi, Herb uses the filename when reporting errors, so pass
      # the file Tilt loaded the template from if the caller did not set one.
      @options[:filename] ||= file

      engine_class = @options[:engine_class] || Herb::Engine

      # If :freeze option is given, the intent is to setup frozen string
      # literals in the template.  So enable frozen string literals in the
      # code Tilt generates if the :freeze option is given.
      if @freeze_string_literals = !!@options[:freeze]
        # Passing the :freeze option to Herb sets the
        # frozen-string-literal magic comment, which doesn't have an effect
        # with Tilt as Tilt wraps the resulting code.  Worse, the magic
        # comment appearing not at the top of the file can cause a warning.
        # So remove the :freeze option before passing to Herb.
        @options.delete(:freeze)

        # Herb by default appends .freeze to template literals, but that is
        # not necessary and slows down code when Tilt is using frozen string
        # literals, so pass the :freeze_template_literals option to not
        # append .freeze.
        @options[:freeze_template_literals] = false
      end

      @engine = engine_class.new(@data, @options)
      @outvar = @engine.bufvar
      @src = @engine.src

      @engine
    end

    def precompiled_template(locals)
      @src
    end

    def freeze_string_literals?
      @freeze_string_literals
    end
  end
end
