# Set RAILS_ROOT and load the environment if it's not already loaded.
unless defined?(Rails)
  ENV["RAILS_ROOT"] = File.expand_path("../example", __FILE__)
  require File.expand_path("../example/config/environment", __FILE__)
end

Teaspoon.configure do |config|
  config.driver = ENV['TEASPOON_DRIVER'] || "phantomjs"
  config.mount_at = "/teaspoon"
  config.root = TurboGraft::Engine.root
  config.asset_paths = ["test/javascripts"]
  config.fixture_paths = ["test/javascripts/fixtures"]

  config.suite do |suite|
    suite.use_framework :mocha
    suite.matcher = "{test/javascripts,app/assets}/**/*_test.{js,js.coffee,coffee}"
    suite.helper = "test_helper"
    suite.stylesheets = ["teaspoon"]
  end
end
