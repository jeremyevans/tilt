require_relative 'test_helper'
require 'tilt/cli'
require 'stringio'

describe 'bin/tilt' do
  def tilt(*argv)
    stdin, stdout, stderr = a = Array.new(3){StringIO.new}
    if block_given?
      yield(stdin)
      stdin.rewind
    end
    res = Tilt::CLI.run(argv: argv, stdin: stdin, stdout: stdout, stderr: stderr, script_name: 'tilt-test')
    stdout.rewind
    stderr.rewind
    [res, stdout.read, stderr.read]
  end

  it "should show error message if no template given" do
    exit_code, stdout, stderr = tilt
    assert_equal 1, exit_code
    assert_equal "template type not given. see: tilt-test --help\n", stderr
    assert_empty stdout
  end

  it "should render template if not given options" do
    exit_code, stdout, stderr = tilt('test/mytemplate.erb')
    assert_equal 0, exit_code
    assert_empty stderr
    assert_equal "Answer: 2\n", stdout
  end

  it "should show usage with -h" do
    exit_code, stdout, stderr = tilt('-h')
    assert_equal 0, exit_code
    assert_empty stderr
    assert_includes stdout, "Usage: tilt <options> <file>"
  end

  it "should list available template engines with -l" do
    exit_code, stdout, stderr = tilt('-l')
    assert_equal 0, exit_code
    assert_empty stderr
    assert_includes stdout, "\nERB                  erb, rhtml\n"
  end

  it "should show error message for invalid implicit engine" do
    exit_code, stdout, stderr = tilt('foo.bogus')
    assert_equal 1, exit_code
    assert_equal "template engine not found for: foo.bogus\n", stderr
    assert_empty stdout
  end

  it "should show error message for invalid explicit engine" do
    exit_code, stdout, stderr = tilt('-t', 'bogus')
    assert_equal 1, exit_code
    assert_equal "unknown template type: bogus\n", stderr
    assert_empty stdout
  end

  it "should support -t for type" do
    exit_code, stdout, stderr = tilt('-t', 'erb'){|s| s.write("Answer: <%= 3 %>")}
    assert_equal 0, exit_code
    assert_empty stderr
    assert_includes stdout, "Answer: 3"
  end

  it "should support -y for layout file" do
    exit_code, stdout, stderr = tilt('-y', 'test/mylayout.erb', 'test/mytemplate.erb')
    assert_equal 0, exit_code
    assert_empty stderr
    assert_equal "Before\nAnswer: 2\nAfter\n", stdout.sub("\n\n", "\n")
  end

  it "should show error message for invalid engine" do
    exit_code, stdout, stderr = tilt('-y', 'bogus')
    assert_equal 1, exit_code
    assert_equal "no such layout: bogus\n", stderr
    assert_empty stdout
  end

  it "should support -D option for locals" do
    exit_code, stdout, stderr = tilt('-Dn=3', 'test/mylocalstemplate.erb')
    assert_equal 0, exit_code
    assert_empty stderr
    assert_equal "Answer: 23\n", stdout
  end

  it "should support -d option for locals specified by yaml file" do
    exit_code, stdout, stderr = tilt('-d', 'test/mylocalstemplate.yml', 'test/mylocalstemplate.erb')
    assert_equal 0, exit_code
    assert_empty stderr
    assert_equal "Answer: 24\n", stdout
  end

  it "should show error message for nonexistant yaml file" do
    exit_code, stdout, stderr = tilt('-d', 'bogus')
    assert_equal 1, exit_code
    assert_equal "no such define file: bogus\n", stderr
    assert_empty stdout
  end

  it "should show error message for invalid yaml file" do
    exit_code, stdout, stderr = tilt('-d', 'test/mylayout.erb')
    assert_equal 1, exit_code
    assert_equal "vars must be a Hash, not instance of String\n", stderr
    assert_empty stdout
  end

  it "should support --vars option for locals " do
    exit_code, stdout, stderr = tilt('--vars={"n"=>"4"}', 'test/mylocalstemplate.erb')
    assert_equal 0, exit_code
    assert_empty stderr
    assert_equal "Answer: 24\n", stdout
  end

  it "should show error message for invalid --vars" do
    exit_code, stdout, stderr = tilt('--vars=""')
    assert_equal 1, exit_code
    assert_equal "vars must be a Hash, not instance of String\n", stderr
    assert_empty stdout
  end
end
