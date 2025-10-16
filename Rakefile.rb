# frozen_string_literal: true

require "rake/testtask"

# Default task - run tests with RBS runtime checking
task default: :test

Rake::TestTask.new(:test) do |t|
  t.test_files = FileList["test/**/*_test.rb"]
  t.verbose = true

  t.ruby_opts << "-r rbs/test/setup"
  ENV["RBS_TEST_TARGET"] = "GoldyLox::*"
end

Rake::TestTask.new(:test_no_rbs) do |t|
  t.test_files = FileList["test/**/*_test.rb"]
  t.verbose = true

  t.description = "Run tests (without RBS)"
end
