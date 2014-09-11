# Provide a simple gemspec so you can easily use your enginex
# project in your rails apps through git.
Gem::Specification.new do |s|
  s.name = "turbomodules"
  s.summary = "Insert Turbomodules summary."
  s.description = "Insert Turbomodules description."
  s.authors = "Nicholas Simmons, Tyler Mercier, Anthony Cameron, Patrick Donovan"
  s.homepage = "https://github.com/Shopify/turbomodules"
  s.license = "MIT"
  s.files = Dir["lib/assets/*.coffee", "lib/turbomodules.rb"] + ["MIT-LICENSE", "Rakefile", "Gemfile", "README.rdoc"]
  s.version = "0.0.1"
end
