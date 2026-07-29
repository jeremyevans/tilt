# frozen_string_literal: true

# = Herb (<tt>herb</tt>, <tt>html.erb</tt>)
#
# {Herb}[https://herb-tools.dev] is an HTML-aware ERB implementation. Unlike
# other ERB implementations, Herb parses the HTML in the template in addition
# to the embedded Ruby, which allows it to detect problems such as unclosed or
# mismatched tags at compile time, and to escape interpolated values based on
# where they appear in the document (element content, attribute value, script
# or style content).
#
# Herb's engine is API compatible with {Erubi}[rdoc-ref:lib/tilt/erubi.rb], so
# the documentation for that template engine applies in addition to the
# following.
#
# === Example
#
#     <div class="container">
#       <% if logged_in? %>
#         <h1>Hello <%= user.name %>!</h1>
#       <% end %>
#     </div>
#
# === Usage
#
# The <tt>Tilt::HerbTemplate</tt> class is registered for all files ending in
# <tt>.herb</tt> or <tt>.html.erb</tt> by default. It is not registered for
# <tt>.erb</tt> itself, since that would change which engine is used for
# existing templates. To use Herb for all ERB templates, use:
#
#     Tilt.register Tilt::HerbTemplate, 'erb', 'rhtml'
#
# __NOTE:__ It's suggested that your program <tt>require 'herb'</tt> at load
# time when using this template engine within a threaded environment.
#
# === Options
#
# ==== <tt>:engine_class => Herb::Engine</tt>
#
# Allows you to specify a custom engine class to use instead of the
# default which is <tt>Herb::Engine</tt>.
#
# ==== <tt>:escape => false</tt>
#
# When true, <tt><%= %></tt> escapes its output and <tt><%== %></tt> does not,
# reversing the default behavior. Herb escapes based on context, so values
# interpolated into attribute values, <tt><script></tt> content, and
# <tt><style></tt> content use the escaping appropriate for that context.
#
# ==== <tt>:validation_mode => :raise</tt>
#
# How to handle parser and validation errors:
#
# <tt>:raise</tt> :: raise <tt>Herb::Engine::CompilationError</tt> when
#                    creating the template (the default).
# <tt>:overlay</tt> :: render the errors into the template output.
# <tt>:none</tt> :: ignore the errors.
#
# ==== Other
#
# Other options are passed to the constructor of the engine class.
#
# === See also
#
# * {Herb Home}[https://herb-tools.dev]
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
