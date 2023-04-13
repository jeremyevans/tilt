require_relative 'template'
require 'wikicloth'

# WikiCloth implementation. See: https://github.com/nricciar/wikicloth
Tilt::WikiClothTemplate = Tilt::StaticTemplate.subclass do
  (options.delete(:parser) || WikiCloth::Parser).new(options.merge(:data => data)).to_html
end
