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

Dependo::Registry[:config_pool].all.each do |config|
    Dependo::Registry[:log].info "Config: "
    Dependo::Registry[:log].info "CA Cert:"+config.ca_cert.subject.to_s
    Dependo::Registry[:log].info "OCSP Cert (may be the same as above):"+config.ocsp_cert.subject.to_s
    Dependo::Registry[:log].info "OCSP Validity Hours: "+config.ocsp_validity_hours.to_s
    Dependo::Registry[:log].info "\n"
end

server = R509::CertificateAuthority::Http::Server

run server
