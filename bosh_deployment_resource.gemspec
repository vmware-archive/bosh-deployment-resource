# coding: utf-8

Gem::Specification.new do |spec|
  spec.name          = "bosh_deployment_resource"
  spec.version       = "0.0.1"
  spec.summary       = "a gem for things"
  spec.authors       = ["Chris Brown", "Alex Suraci"]

  spec.files         = Dir.glob("{lib,bin}/**/*")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "minitar"
  spec.add_dependency "faraday"

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "webmock", "~> 1.21.0"
end
