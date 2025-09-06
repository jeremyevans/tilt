task :default => [:test]

desc "Run tests"
task :test do
  sh "#{FileUtils::RUBY} #{"-w" if RUBY_VERSION >= '3'} #{'-W:strict_unused_block' if RUBY_VERSION >= '3.4'} test/all.rb"
end

desc "Generate rdoc"
task :rdoc do
  rdoc_dir = "rdoc"
  rdoc_opts = ["--line-numbers", '--title', 'Tilt']

  begin
    gem 'hanna'
    rdoc_opts.concat(['-f', 'hanna'])
  rescue Gem::LoadError
  end

  rdoc_opts.concat(['--main', 'README.md', "-o", rdoc_dir] +
    %w"README.md CHANGELOG.md COPYING" +
    Dir["lib/**/*.rb"]
  )

  FileUtils.rm_rf(rdoc_dir)

  require "rdoc"
  RDoc::RDoc.new.document(rdoc_opts)
end

desc "Run tests with coverage"
task :test_cov do
  ENV['COVERAGE'] = '1'
  sh "#{FileUtils::RUBY} test/all.rb"
end

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

desc 'Build packages'
task :package do
  sh "gem build tilt.gemspec"
end
