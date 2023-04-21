# frozen_string_literal: true
require_relative 'template'
require 'prawn'

module Tilt
  # Prawn template implementation. See: http://prawnpdf.org
  class PrawnTemplate < Template
    self.default_mime_type = 'application/pdf'
    
    def prepare
      @options[:page_size] = 'A4' unless @options.has_key?(:page_size)
      @options[:page_layout] = :portrait unless @options.has_key?(:page_layout)
      @engine = ::Prawn::Document.new(@options)
    end
    
    def evaluate(scope, locals, &block)
      pdf = @engine
      if @data.respond_to?(:to_str)
        locals = locals.dup
        locals[:pdf] = pdf
        super
      else
        warn "Non-string provided as prawn template data. This is no longer supported and support for it will be removed in Tilt 2.3", :uplevel=>2
        # :nocov:
        @data.call(pdf) if @data.kind_of?(Proc)
        # :nocov:
      end
      pdf.render
    end
    
    def precompiled_template(locals)
      @data.to_str
    end
  end
end
