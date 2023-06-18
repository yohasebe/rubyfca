# frozen_string_literal: true

require File.expand_path("lib/rubyfca/version", __dir__)

Gem::Specification.new do |gem|
  gem.name          = "rubyfca"
  gem.version       = RubyFCA::VERSION
  gem.authors       = ["Yoichiro Hasebe", "Kow Kuroda"]
  gem.email         = ["yohasebe@gmail.com"]
  gem.summary       = "Command line FCA tool written in Ruby"
  gem.description   = "Command line Formal Concept Analysis (FCA) tool written in Ruby"
  gem.homepage      = "http://github.com/yohasebe/rubyfca"

  gem.required_ruby_version = ">= 2.6.10"
  gem.licenses      = ["GPL-3.0"]
  gem.files         = `git ls-files`.split("\n")
  gem.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  gem.require_paths = ["lib"]

  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})

  gem.add_dependency "optimist"
  gem.add_dependency "roo"
  gem.add_development_dependency "minitest"
end
