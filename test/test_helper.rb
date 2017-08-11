ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'
require 'minitest/reporters'
require 'capybara'
require 'capybara/dsl'
require 'byebug'

require File.expand_path('../example/config/environment.rb',  __FILE__)
require 'rails/test_help'

Capybara.app = Example::Application
# selenium_chrome may work nicely
Capybara.current_driver = ENV['CAPYBARA_DRIVER'].try(:to_sym) || :selenium
Capybara.default_max_wait_time = 2

Minitest::Reporters.use!(Minitest::Reporters::DefaultReporter.new(color: true))

Dir[File.dirname(__FILE__) + '/../lib/*.rb'].each do |file|
  require File.basename(file, File.extname(file))
end
