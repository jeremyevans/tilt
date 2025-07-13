require_relative 'test_helper'

checked_describe('tilt/prawn', 'pdf-reader') do
  _PdfOutput = Class.new do
    def initialize(pdf_raw)
      @reader = PDF::Reader.new(StringIO.new(pdf_raw))
    end
    
    def text
      @reader.pages.map(&:text).join
    end

    def page_count
      @reader.page_count
    end
    
    def page_attributes(page_num=1)
      @reader.page(page_num).attributes
    end
  end

  it "is registered for '.prawn' files" do
    assert_equal Tilt::PrawnTemplate, Tilt['test.prawn']
  end

  it "renders inline prawn templates" do
    template = Tilt::PrawnTemplate.new { |t| "pdf.text \"Hello PDF!\"" }
    3.times do
      output   = _PdfOutput.new(template.render)
      assert_includes output.text, "Hello PDF!"
    end
  end
  
  it "supports yielding to render" do
    template = Tilt::PrawnTemplate.new { |t| "yield pdf" }
    3.times do
      output   = _PdfOutput.new(template.render{|pdf| pdf.text 'Hello PDF!'})
      assert_includes output.text, "Hello PDF!"
    end
  end
  
  it "renders templates from a file" do
    template = Tilt::PrawnTemplate.new("test/tilt_prawntemplate.prawn")
    3.times do
      output   = _PdfOutput.new(template.render)
      assert_equal 2, output.page_count
      assert_equal output.text, "Hello Template!"
    end
  end
  
  it "defaults to A4 page size & portrait layout settings" do
    template = Tilt::PrawnTemplate.new { |t| "pdf.text \"Hello A4 portrait!\"" }
    output   = _PdfOutput.new(template.render)
    assert_includes output.text, "Hello A4 portrait!"
    assert_equal [0, 0, 595.28, 841.89], output.page_attributes(1)[:MediaBox]
  end
  
  it "allows page size & layout settings - A3 landscape" do
    template = Tilt::PrawnTemplate.new( :page_size => 'A3', :page_layout => :landscape) { |t| "pdf.text \"Hello A3 landscape!\"" }
    output   = _PdfOutput.new(template.render)
    assert_includes output.text, "Hello A3 landscape!"
    assert_equal [0, 0, 1190.55, 841.89], output.page_attributes(1)[:MediaBox]
  end
end
