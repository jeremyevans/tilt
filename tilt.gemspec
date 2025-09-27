require './lib/tilt'

Gem::Specification.new do |s|
  s.name = 'tilt'
  s.version = Tilt::VERSION

  s.description = "Generic interface to multiple Ruby template engines"
  s.summary     = s.description
  s.license     = "MIT"

  s.authors = ["Ryan Tomayko", "Magnus Holm", "Jeremy Evans"]
  s.email = "code@jeremyevans.net"

  s.files = %w'COPYING bin/tilt' + Dir["lib/**/*.rb"]
  s.executables = ['tilt']

  s.homepage = "https://github.com/jeremyevans/tilt"
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "Tilt", "--main", "Tilt"]
  s.require_paths = %w[lib]
  s.required_ruby_version = ">= 2.0"

  s.metadata = {
    'bug_tracker_uri'   => 'https://github.com/jeremyevans/tilt/issues',
    'changelog_uri'     => 'https://github.com/jeremyevans/tilt/blob/master/CHANGELOG.md',
    'mailing_list_uri'  => 'https://github.com/jeremyevans/tilt/discussions',
    'source_code_uri'   => 'https://github.com/jeremyevans/tilt',
    'documentation_uri' => 'https://tilt.jeremyevans.net',
  }
end
