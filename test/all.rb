files = Dir['./test/*_test.rb']

# For reasons not currently understood, requiring haml breaks coverage
# testing.  As Tilt::HamlTemplate uses Haml::Template in current
# versions of haml, there isn't much point in coverage for it.
files.delete('./test/tilt_hamltemplate_test.rb') if ENV['COVERAGE']

files.each{|f| require f} 
