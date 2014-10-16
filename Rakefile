#!/usr/bin/env rake
require 'bundler'
require 'bundler/gem_tasks'
require 'rake/testtask'

APP_RAKEFILE = File.expand_path("../test/example/Rakefile", __FILE__)
load "rails/tasks/engine.rake"

task default: 'test'

desc "Run the javascript specs"
task :teaspoon => "app:teaspoon"

desc "Run ci suite"
task :ci => [:teaspoon, :test]

Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.libs << 'test'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end
