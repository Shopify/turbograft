ENV["RACK_ENV"] = "test"

require "minitest/autorun"
require "minitest/reporters"

Minitest::Reporters.use!(Minitest::Reporters::DefaultReporter.new(color: true))

require File.expand_path("../example/config/environment.rb",  __FILE__)
require "rails/test_help"

Dir[File.dirname(__FILE__) + '/../lib/*.rb'].each do |file|
  require File.basename(file, File.extname(file))
end
