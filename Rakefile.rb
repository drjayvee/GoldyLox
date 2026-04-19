# frozen_string_literal: true

require "rake/testtask"
require "rubocop/rake_task"

RuboCop::RakeTask.new

# Default task - run tests with RBS runtime checking
task default: :test

Rake::TestTask.new(:test) do |t|
  t.test_files = FileList["test/**/*_test.rb"]
  t.verbose = true

  t.ruby_opts << "-r rbs/test/setup"
  ENV["RBS_TEST_TARGET"] = "GoldyLox::*"
  ENV["RBS_TEST_LOGLEVEL"] = "warn"
end

Rake::TestTask.new(:test_no_rbs) do |t|
  t.test_files = FileList["test/**/*_test.rb"]
  t.verbose = true

  t.description = "Run tests (without RBS)"
end

task :rbs_validate do
  sh "rbs -I sig validate"
end

desc "Run all checks (RuboCop, RBS validation, tests with RBS)"
task ci: %i[rubocop rbs_validate test]
