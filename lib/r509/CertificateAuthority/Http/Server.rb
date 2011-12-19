require 'rubygems' if RUBY_VERSION < "1.9"
require 'sinatra/base'
require 'r509'
require 'r509/Validity/Redis'
require "#{File.dirname(__FILE__)}/SubjectParser"
require "#{File.dirname(__FILE__)}/ValidityPeriodConverter"
require "#{File.dirname(__FILE__)}/Factory"
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
                    puts yaml_config.inspect

                    #redis = Redis.new

                    config = R509::Config::CaConfig.from_yaml("ca", File.read("config.yaml"))

                    set :crl, R509::Crl.new(config)
                    set :ca, R509::CertificateAuthority::Signer.new(config)
                    set :subject_parser, R509::CertificateAuthority::Http::SubjectParser.new
                    set :validity_period_converter, R509::CertificateAuthority::Http::ValidityPeriodConverter.new
                    set :csr_factory, R509::CertificateAuthority::Http::Factory::CsrFactory.new
                    set :spki_factory, R509::CertificateAuthority::Http::Factory::SpkiFactory.new
                end

                before do
                    content_type :text
                end

                helpers do
                    def crl
                        settings.crl
                    end
                    def ca
                        settings.ca
                    end
                    def subject_parser
                        settings.subject_parser
                    end
                    def validity_period_converter
                        settings.validity_period_converter
                    end
                    def csr_factory
                        settings.csr_factory
                    end
                    def spki_factory
                        settings.spki_factory
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
                    puts env["sinatra.error"].inspect
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

                    if not params.has_key?("profile")
                        raise ArgumentError, "Must provide a CA profile"
                    end
                    if not params.has_key?("validityPeriod")
                        raise ArgumentError, "Must provide a validity period"
                    end
                    if not params.has_key?("csr") and not params.has_key?("spki")
                        raise ArgumentError, "Must provide a CSR or SPKI"
                    end

                    subject = subject_parser.parse(raw, "subject")
                    puts subject.inspect
                    puts subject.to_s
                    if subject.empty?
                        raise ArgumentError, "Must provide a subject"
                    end

                    if params.has_key?("extensions") and params["extensions"].has_key?("subjectAlternativeName")
                        san_names = params["extensions"]["subjectAlternativeName"]
                    else
                        san_names = []
                    end

                    data_hash = {
                        :subject => subject,
                        :san_names => san_names
                    }

                    validity_period = validity_period_converter.convert(params["validityPeriod"])

                    if params.has_key?("csr")
                        csr = csr_factory.build(:csr => params["csr"])
                        cert = ca.sign_cert(
                            :csr => csr,
                            :profile_name => params["profile"],
                            :data_hash => data_hash,
                            :not_before => validity_period[:not_before],
                            :not_after => validity_period[:not_after]
                        )
                    elsif params.has_key?("spki")
                        spki = spki_factory.build(:spki => params["spki"], :subject => subject)
                        cert = ca.sign_cert(
                            :spki => spki,
                            :profile_name => params["profile"],
                            :data_hash => data_hash,
                            :not_before => validity_period[:not_before],
                            :not_after => validity_period[:not_after]
                        )
                    else
                        raise ArgumentError, "Must provide a CSR or SPKI"
                    end

                    pem = cert.to_pem
                    puts pem
                    puts pem.size

                    #Base64::encode64(pem)
                    pem
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
