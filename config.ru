require './lib/r509/certificateauthority/http/server'
#require 'r509/middleware/validity'

#use R509::Middleware::Validity
server = R509::CertificateAuthority::Http::Server
server.send(:set, :log, Logger.new(STDOUT))
#server.send(:set, :environment, :test)
run server
