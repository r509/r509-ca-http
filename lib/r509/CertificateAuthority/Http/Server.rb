require 'rubygems' if RUBY_VERSION < "1.9"
require 'sinatra/base'
require 'r509'
require 'r509/Validity/Redis'
require "#{File.dirname(__FILE__)}/SubjectParser"
require 'base64'
require 'redis'
require 'yaml'
require 'logger'

module R509
    module CertificateAuthority
        module Http
            class Server < Sinatra::Base
                configure do
                    disable :protection #disable Rack::Protection (for speed)
                    enable :logging
                    #set :environment, :production

                    yaml_config = YAML::load(File.read("config.yaml"))

                    #redis = Redis.new

                    config = R509::Config::CaConfig.new(
                        :ca_cert =>
                            R509::Cert.new(
                                :cert => File.read(yaml_config["ca"]["cer_filename"]),
                                :key => File.read(yaml_config["ca"]["key_filename"])
                            )
                    )

                    set :crl, R509::Crl.new(config)
                end

                helpers do
                    def crl
                        settings.crl
                    end
                    def log
                        settings.log
                    end
                end

                configure :production do
                    set :log, Logger.new(STDOUT)
                end

                configure :development do
                    set :log, Logger.new(STDOUT)
                end

                configure :test do
                    set :log, Logger.new(nil)
                end

                error do
                    "Something is amiss with our CA. You should ... wait?"
                end

                error StandardError do
                    env["sinatra.error"].message
                end

                get '/favicon.ico' do
                    log.debug "go away. no children."
                    "go away. no children"
                end

                get '/1/crl/get/?' do
                    log.info "Get CRL"
                    crl.to_pem
                end

                get '/1/crl/generate/?' do
                    log.info "Generate CRL"
                    crl.generate_crl
                end

                post '/1/certificate/issue/?' do
                    log.info "Issue Certificate"
                    raw = request.env["rack.input"].read
                    puts raw

                    puts params.inspect

                    parsed = Rack::Utils::parse_nested_query(raw)
                    puts parsed.inspect

                    amped = Rack::Utils::unescape("rack%26ah")
                    puts amped

                    subject_parser = R509::CertificateAuthority::Http::SubjectParser.new
                    subject = subject_parser.parse(raw, "sub")
                    puts subject.inspect
                    if subject.empty?
                        raise ArgumentError, "Must provide a subject"
                    end
                    "Not implemented"
                end

                post '/1/certificate/revoke/?' do
                    log.info "Revoke Certificate"
                    serial = params[:serial]
                    reason = params[:reason]

                    if not serial
                        raise ArgumentError, "Serial must be provided"
                    end
                    if not reason
                        reason = 0
                    end

                    crl.revoke_cert(serial.to_i, reason.to_i)

                    crl.to_pem
                end

                post '/1/certificate/unrevoke/?' do
                    log.info "Unrevoke Certificate"
                    serial = params[:serial]

                    if not serial
                        raise ArgumentError, "Serial must be provided"
                    end

                    crl.unrevoke_cert(serial.to_i)

                    crl.to_pem
                end
            end
        end
    end
end
