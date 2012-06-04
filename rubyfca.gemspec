# -*- encoding: utf-8 -*-
require File.expand_path('../lib/rubyfca/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Yoichiro Hasebe", "Kow Kuroda"]
  gem.email         = ["yohasebe@gmail.com"]
  gem.summary         = %q{Command line FCA tool written in Ruby}  
  gem.description     = %q{Command line Formal Concept Analysis (FCA) tool written in Ruby}  
  gem.homepage        = "http://github.com/yohasebe/rubyfca"  

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "rubyfca"  
  gem.require_paths = ["lib"]
  gem.version       = RubyFCA::VERSION  
end
