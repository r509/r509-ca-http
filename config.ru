require 'r509'
require 'dependo'
require 'logger'
#require 'r509/middleware/validity'
#require 'r509/middleware/certwriter'

#use R509::Middleware::Certwriter
#use R509::Middleware::Validity

config_data = File.read("config.yaml")

Dependo::Registry[:config_pool] = R509::Config::CaConfigPool.from_yaml("certificate_authorities", config_data)

Dependo::Registry[:log] = Logger.new(STDOUT)

require './lib/r509/certificateauthority/http/server'

server = R509::CertificateAuthority::Http::Server

run server
