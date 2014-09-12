ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'
require 'minitest/reporters'
require 'capybara'
require 'capybara/dsl'
require 'capybara/poltergeist'
require 'byebug'

require File.expand_path('../example/config/environment.rb',  __FILE__)
require 'rails/test_help'

Capybara.app = Example::Application
Capybara.current_driver = :poltergeist #:rack_test, :selenium

Minitest::Reporters.use!(Minitest::Reporters::DefaultReporter.new(color: true))

Dir[File.dirname(__FILE__) + '/../lib/*.rb'].each do |file|
  require File.basename(file, File.extname(file))
end
