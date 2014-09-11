ENV["RACK_ENV"] = "test"

require "minitest/autorun"
require "minitest/reporters"

Minitest::Reporters.use!(Minitest::Reporters::DefaultReporter.new(color: true))

require File.expand_path("../dummy/config/environment.rb",  __FILE__)
require "rails/test_help"

Dir[File.dirname(__FILE__) + '/../lib/*.rb'].each do |file|
  require File.basename(file, File.extname(file))
end




# Rails.backtrace_cleaner.remove_silencers!

# # Load support files
# Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

# # Load fixtures from the engine
# if ActiveSupport::TestCase.method_defined?(:fixture_path=)
#   ActiveSupport::TestCase.fixture_path = File.expand_path("../fixtures", __FILE__)
# end

# Dummy::Application.load_tasks
# Rake::Task['db:migrate'].invoke

