require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

Rake::Task[:build].enhance [:spec]

task :default => :spec
