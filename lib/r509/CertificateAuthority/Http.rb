require 'rubygems' if RUBY_VERSION < "1.9"
require 'sinatra/base'
require 'r509'
require 'r509/Validity/Redis'
require 'base64'
require 'redis'
require 'yaml'
require 'logger'

module R509
    module CertificateAuthority
        class Http < Sinatra::Base
            configure do
                disable :protection #disable Rack::Protection (for speed)
                enable :logging
                #set :environment, :production

                yaml_config = YAML::load(File.read("config.yaml"))

                #redis = Redis.new

                config = R509::Config.new(
                    :ca_cert =>
                        R509::Cert.new(
                            :cert => File.read(yaml_config["ca"]["cer_filename"]),
                            :key => File.read(yaml_config["ca"]["key_filename"])
                        )
                )
            end

            configure :production do
                LOG = Logger.new(STDOUT)
            end

            configure :development do
                LOG = Logger.new(STDOUT)
            end

            configure :test do
                LOG = Logger.new(nil)
            end

            error do
                "Something is amiss with our OCSP responder. You should ... wait?"
            end

            get '/favicon.ico' do
                LOG.debug "go away. no children."
                "go away. no children"
            end

            get '/1/crl/get/?' do
                LOG.info "Get CRL"
            end

            get '/1/crl/generate/?' do
                LOG.info "Generate CRL"
            end

            post '/1/certificate/issue/?' do
                Log.info "Issue Certificate"
            end

            post '/1/certificate/revoke/?' do
                Log.info "Revoke Certificate"
            end
        end
    end
end
