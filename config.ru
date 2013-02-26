require 'r509'
require 'dependo'
require 'logger'

Dependo::Registry[:log] = Logger.new(STDOUT)

begin
  gem 'r509-middleware-validity'
  require 'r509/middleware/validity'
  use R509::Middleware::Validity
  Dependo::Registry[:log].info "Using r509 middleware validity"
rescue Gem::LoadError
end

begin
  gem 'r509-middleware-certwriter'
  require 'r509/middleware/certwriter'
  use R509::Middleware::Certwriter
  Dependo::Registry[:log].info "Using r509 middleware certwriter"
rescue Gem::LoadError
end

config_data = File.read("config.yaml")

Dependo::Registry[:config_pool] = R509::Config::CAConfigPool.from_yaml("certificate_authorities", config_data)

require 'r509/certificateauthority/http/server'

Dependo::Registry[:config_pool].all.each do |config|
  Dependo::Registry[:log].info "Config: "
  Dependo::Registry[:log].info "CA Cert:"+config.ca_cert.subject.to_s
  Dependo::Registry[:log].info "OCSP Cert (may be the same as above):"+config.ocsp_cert.subject.to_s
  Dependo::Registry[:log].info "OCSP Validity Hours: "+config.ocsp_validity_hours.to_s
  Dependo::Registry[:log].info "CRL Validity Hours: "+config.crl_validity_hours.to_s
  Dependo::Registry[:log].info "\n"
end

server = R509::CertificateAuthority::HTTP::Server

run server
