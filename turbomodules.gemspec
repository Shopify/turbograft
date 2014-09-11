# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'turbomodules/version'

Gem::Specification.new do |spec|
  spec.name          = "turbomodules"
  spec.version       = TurboModules::VERSION
  spec.authors       = ["Nicholas Simmons", "Tyler Mercier", "Anthony Cameron", "Patrick Donovan"]
  spec.email         = ["tylermercier@gmail.com"]
  spec.summary       = "Insert Turbomodules summary."
  spec.homepage      = "https://github.com/Shopify/turbomodules"
  spec.license       = "MIT"

  spec.files         = Dir["lib/assets/javascripts/*.js.coffee", "lib/turbomodules.rb", "lib/turbomodules/*.rb", "README.md", "MIT-LICENSE"]
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "coffee-rails"
  spec.add_dependency "rails", ">= 3.2.18"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "minitest-reporters"
  spec.add_development_dependency "teaspoon"
  spec.add_development_dependency "sqlite3"
  spec.add_development_dependency "thin"
end
