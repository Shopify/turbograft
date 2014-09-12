# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'graft/version'

Gem::Specification.new do |spec|
  spec.name          = "graft"
  spec.version       = Graft::VERSION
  spec.authors       = ["Nicholas Simmons", "Tyler Mercier", "Anthony Cameron", "Patrick Donovan"]
  spec.email         = ["tylermercier@gmail.com"]
  spec.summary       = "It's like turbolinks, but with partial page replacement and tests"
  spec.homepage      = "https://github.com/Shopify/graft"
  spec.license       = "MIT"

  spec.files         = Dir["lib/assets/javascripts/*.js.coffee", "lib/graft.rb", "lib/graft/*.rb", "README.md", "MIT-LICENSE"]
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "coffee-rails"
  spec.add_dependency "rails"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "sass-rails"
  spec.add_development_dependency "jquery-rails"
  spec.add_development_dependency "uglifier"
  spec.add_development_dependency "minitest-reporters"
  spec.add_development_dependency "capybara"
  spec.add_development_dependency "selenium-webdriver"
  spec.add_development_dependency "poltergeist"
  spec.add_development_dependency "teaspoon"
  spec.add_development_dependency "sqlite3"
  spec.add_development_dependency "thin"
  spec.add_development_dependency "byebug"
end
