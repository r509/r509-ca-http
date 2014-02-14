module R509::CertificateAuthority::HTTP
  class Config
    def self.load_config
      config_data = File.read("config.yaml")

      Dependo::Registry[:config_pool] = R509::Config::CAConfigPool.from_yaml("certificate_authorities", config_data)
    end

    def self.print_config
      Dependo::Registry[:log].warn "Config loaded"
      Dependo::Registry[:config_pool].all.each do |config|
        Dependo::Registry[:log].warn "Config: "
        Dependo::Registry[:log].warn "CA Cert:"+config.ca_cert.subject.to_s
        Dependo::Registry[:log].warn "OCSP Cert (may be the same as above):"+config.ocsp_cert.subject.to_s
        Dependo::Registry[:log].warn "OCSP Validity Hours: "+config.ocsp_validity_hours.to_s
        Dependo::Registry[:log].warn "CRL Validity Hours: "+config.crl_validity_hours.to_s
        Dependo::Registry[:log].warn "\n"
      end
    end
  end
end
