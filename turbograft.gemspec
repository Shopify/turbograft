# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'turbograft/version'

Gem::Specification.new do |spec|
  spec.name          = "turbograft"
  spec.version       = TurboGraft::VERSION
  spec.authors       = ["Kristian Plettenberg-Dussault", "Justin Li", "Nicholas Simmons", "Tyler Mercier", "Anthony Cameron", "Patrick Donovan"]
  spec.email         = ["tylermercier@gmail.com"]
  spec.summary       = "turbolinks with partial page replacement"
  spec.description   = "It's like turbolinks, but with partial page replacement and tests"
  spec.homepage      = "https://github.com/Shopify/turbograft"
  spec.license       = "MIT"

  spec.files         = Dir["lib/**/*", "README.md", "MIT-LICENSE"]
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '~> 2.1'

  spec.add_dependency "coffee-rails"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rails"
  spec.add_development_dependency "jquery-rails"
  spec.add_development_dependency "minitest-reporters"
  spec.add_development_dependency "capybara"
  spec.add_development_dependency "selenium-webdriver"
  spec.add_development_dependency "teaspoon-mocha"
  spec.add_development_dependency "sqlite3"
  spec.add_development_dependency "thin"
  spec.add_development_dependency "byebug"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "pry-byebug"
end
