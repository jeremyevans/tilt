require 'rake/testtask'
task :default => [:test]

# SPECS =====================================================================

desc 'Run tests (default)'
Rake::TestTask.new(:test) do |t|
  t.test_files = FileList['test/*_test.rb']
  t.warning = false
end

# DOCUMENTATION =============================================================

begin
  require 'yard'
  YARD::Rake::YardocTask.new do |t|
    t.files = [
      'lib/tilt.rb', 'lib/tilt/mapping.rb', 'lib/tilt/template.rb',
      '-',
      '*.md', 'docs/*.md',
    ]

    t.options <<
      '--no-private' <<
      '--protected' <<
      '-m' << 'markdown' <<
      '--asset' << 'docs/common.css:css/common.css'
  end
rescue LoadError
end

# PACKAGING =================================================================

desc 'Build packages'
task :package do
  sh "gem build tilt.gemspec"
end
