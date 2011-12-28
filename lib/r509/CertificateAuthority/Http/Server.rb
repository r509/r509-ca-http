require 'rubygems' if RUBY_VERSION < "1.9"
require 'sinatra/base'
require 'r509'
require "#{File.dirname(__FILE__)}/SubjectParser"
require "#{File.dirname(__FILE__)}/ValidityPeriodConverter"
require "#{File.dirname(__FILE__)}/Factory"
require 'base64'
require 'yaml'
require 'logger'

module R509
    module CertificateAuthority
        module Http
            class Server < Sinatra::Base
                configure do
                    disable :protection #disable Rack::Protection (for speed)
                    disable :logging
                    set :environment, :production

                    yaml_config = YAML::load(File.read("config.yaml"))

                    config_pool = R509::Config::CaConfigPool.from_yaml("certificate_authorities", File.read("config.yaml"))

                    crls = {}
                    certificate_authorities = {}
                    config_pool.names.each do |name|
                        crls[name] = R509::Crl.new(config_pool[name])
                        certificate_authorities[name] = R509::CertificateAuthority::Signer.new(config_pool[name])
                    end

                    set :crls, crls
                    set :certificate_authorities, certificate_authorities
                    set :subject_parser, R509::CertificateAuthority::Http::SubjectParser.new
                    set :validity_period_converter, R509::CertificateAuthority::Http::ValidityPeriodConverter.new
                    set :csr_factory, R509::CertificateAuthority::Http::Factory::CsrFactory.new
                    set :spki_factory, R509::CertificateAuthority::Http::Factory::SpkiFactory.new
                end

                before do
                    content_type :text
                end

                helpers do
                    def crl(name)
                        settings.crls[name]
                    end
                    def ca(name)
                        settings.certificate_authorities[name]
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
                    set :log, Logger.new(nil)
                end

                configure :development do
                    set :log, Logger.new(nil)
                end

                configure :test do
                    set :log, Logger.new(nil)
                end

                error do
                    "Something is amiss with our CA. You should ... wait?"
                end

                error StandardError do
                    log.error env["sinatra.error"].inspect
                    log.error env["sinatra.error"].backtrace.join("\n")
                    env["sinatra.error"].message
                end

                get '/favicon.ico' do
                    log.debug "go away. no children."
                    "go away. no children"
                end

                get '/1/crl/:ca/get/?' do
                    log.info "Get CRL for #{params[:ca]}"

                    if not crl(params[:ca])
                        raise ArgumentError, "CA not found"
                    end

                    crl(params[:ca]).to_pem
                end

                get '/1/crl/:ca/generate/?' do
                    log.info "Generate CRL for #{params[:ca]}"

                    if not crl(params[:ca])
                        raise ArgumentError, "CA not found"
                    end

                    crl(params[:ca]).generate_crl
                end

                post '/1/certificate/issue/?' do
                    log.info "Issue Certificate"
                    raw = request.env["rack.input"].read
                    log.info raw

                    log.info params.inspect

                    if not params.has_key?("ca")
                        raise ArgumentError, "Must provide a CA"
                    end
                    if not ca(params["ca"])
                        raise ArgumentError, "CA not found"
                    end
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
                    log.info subject.inspect
                    log.info subject.to_s
                    if subject.empty?
                        raise ArgumentError, "Must provide a subject"
                    end

                    if params.has_key?("extensions") and params["extensions"].has_key?("subjectAlternativeName")
                        san_names = params["extensions"]["subjectAlternativeName"].select { |name| not name.empty? }
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
                        cert = ca(params["ca"]).sign(
                            :csr => csr,
                            :profile_name => params["profile"],
                            :data_hash => data_hash,
                            :not_before => validity_period[:not_before],
                            :not_after => validity_period[:not_after]
                        )
                    elsif params.has_key?("spki")
                        spki = spki_factory.build(:spki => params["spki"], :subject => subject)
                        cert = ca(params["ca"]).sign(
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
                    log.info pem

                    pem
                end

                post '/1/certificate/revoke/?' do
                    ca = params[:ca]
                    serial = params[:serial]
                    reason = params[:reason]
                    log.info "Revoke for serial #{serial} on CA #{ca}"

                    if not ca
                        raise ArgumentError, "CA must be provided"
                    end
                    if not crl(ca)
                        raise ArgumentError, "CA not found"
                    end
                    if not serial
                        raise ArgumentError, "Serial must be provided"
                    end
                    if not reason
                        reason = 0
                    end

                    crl(ca).revoke_cert(serial.to_i, reason.to_i)

                    crl(ca).to_pem
                end

                post '/1/certificate/unrevoke/?' do
                    ca = params[:ca]
                    serial = params[:serial]
                    log.info "Unrevoke for serial #{serial} on CA #{ca}"

                    if not ca
                        raise ArgumentError, "CA must be provided"
                    end
                    if not crl(ca)
                        raise ArgumentError, "CA not found"
                    end
                    if not serial
                        raise ArgumentError, "Serial must be provided"
                    end

                    crl(ca).unrevoke_cert(serial.to_i)

                    crl(ca).to_pem
                end

                get '/test/certificate/issue/?' do
                    log.info "Loaded test issuance interface"
                    content_type :html
                    erb :test_issue
                end
            end
        end
    end
end
