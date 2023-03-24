require_relative 'template'
require 'prawn'

module Tilt
  # Prawn template implementation. See: http://prawnpdf.org
  class PrawnTemplate < Template
    self.default_mime_type = 'application/pdf'
    
    def prepare
      @engine = ::Prawn::Document.new(prawn_options)
    end
    
    def evaluate(scope, locals, &block)
      pdf = @engine
      if data.respond_to?(:to_str)
        locals[:pdf] = pdf
        super
      else
        warn "Non-string provided as prawn template data. This is no longer supported and support for it will be removed in Tilt 2.3", :uplevel=>2
        # :nocov:
        data.call(pdf) if data.kind_of?(Proc)
        # :nocov:
      end
      pdf.render
    end
    
    def precompiled_template(locals)
      data.to_str
    end
    
    private
      
    def prawn_options
      # default to A4
      { :page_size => "A4", :page_layout => :portrait }.merge(options)
    end
  end
end
