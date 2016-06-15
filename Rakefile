require 'bundler/setup'
require 'bundler/gem_tasks'

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
rescue LoadError
  puts 'rspec not loaded'
end

begin
  require 'rubocop/rake_task'
  RuboCop::RakeTask.new
rescue LoadError
  puts 'rubocop not loaded'
end

begin
  require 'yard'
  YARD::Rake::YardocTask.new
rescue LoadError
  puts 'yard not loaded'
end

task default: [:rubocop, :spec]
