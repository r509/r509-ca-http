$:.push File.expand_path("../lib", __FILE__)
require "r509/certificateauthority/http/version"

spec = Gem::Specification.new do |s|
  s.name = 'r509-ca-http'
  s.version = R509::CertificateAuthority::HTTP::VERSION
  s.platform = Gem::Platform::RUBY
  s.summary = "A (relatively) simple certificate authority API written to work with r509"
  s.description = 'A HTTP CA API for r509'
  s.add_dependency 'r509', '~> 0.9.0'
  s.add_dependency 'sinatra'
  s.add_dependency 'dependo'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'rack-test'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'simplecov'
  s.author = "Sean Schulte"
  s.email = "sirsean@gmail.com"
  s.homepage = "http://vikinghammer.com"
  s.required_ruby_version = ">= 1.9.3"
  s.files = %w(README.md Rakefile) + Dir["{lib,script,spec,doc,cert_data}/**/*"]
  s.test_files= Dir.glob('test/*_spec.rb')
  s.require_path = "lib"
end

