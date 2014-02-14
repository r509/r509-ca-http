require 'r509'
require 'dependo'
require 'logger'
require 'r509/certificateauthority/http/server'

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

R509::CertificateAuthority::HTTP::Config.load_config

R509::CertificateAuthority::HTTP::Config.print_config

server = R509::CertificateAuthority::HTTP::Server
run server
