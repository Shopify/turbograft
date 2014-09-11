# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'turbomodules/version'

Gem::Specification.new do |spec|
  spec.name          = "turbomodules"
  spec.version       = Turbomodules::VERSION
  spec.authors       = ["Nicholas Simmons", "Tyler Mercier", "Anthony Cameron", "Patrick Donovan"]
  spec.email         = ["tylermercier@gmail.com"]
  spec.summary       = "Insert Turbomodules summary."
  spec.description   = %q{Write a longer description. Optional.}
  spec.homepage      = "https://github.com/Shopify/turbomodules"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "minitest-reporters"
  spec.add_development_dependency "teaspoon"
end
