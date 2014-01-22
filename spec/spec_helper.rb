require 'simplecov'
SimpleCov.start
begin
  require 'coveralls'
  Coveralls.wear!
rescue LoadError
end

$:.unshift File.expand_path("../../lib", __FILE__)
$:.unshift File.expand_path("../", __FILE__)
require 'rubygems'
#require 'fixtures'
require 'rspec'
require 'rack/test'
require 'r509'
require 'dependo'
require 'logger'

Dependo::Registry[:config_pool] = R509::Config::CAConfigPool.from_yaml("certificate_authorities", File.read(File.dirname(__FILE__)+"/fixtures/test_config.yaml"), {:ca_root_path => "#{File.dirname(__FILE__)}/fixtures"})

require 'r509/certificateauthority/http/server'

RSpec.configure do |conf|
  conf.include Rack::Test::Methods
end
