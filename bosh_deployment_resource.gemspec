# coding: utf-8

Gem::Specification.new do |spec|
  spec.name          = "bosh_deployment_resource"
  spec.version       = "0.0.1"
  spec.summary       = "a gem for things"
  spec.authors       = ["Chris Brown", "Alex Suraci"]

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
