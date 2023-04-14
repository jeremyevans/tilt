require_relative 'template'

# Raw text (no template functionality).
Tilt::PlainTemplate = Tilt::StaticTemplate.subclass{@data}
