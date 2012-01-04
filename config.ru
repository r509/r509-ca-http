require './lib/r509/CertificateAuthority/Http/Server'
#require 'r509/Middleware/Validity'

#use R509::Middleware::Validity
server = R509::CertificateAuthority::Http::Server
server.send(:set, :log, Logger.new(STDOUT))
#server.send(:set, :environment, :test)
run server
