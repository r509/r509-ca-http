module R509::CertificateAuthority::HTTP
  class Config
    def self.load_config(config_file = "config.yaml")
      config_data = File.read(config_file)

      Dependo::Registry[:config_pool] = R509::Config::CAConfigPool.from_yaml("certificate_authorities", config_data)

      Dependo::Registry[:crls] = {}
      Dependo::Registry[:options_builders] = {}
      Dependo::Registry[:certificate_authorities] = {}
      Dependo::Registry[:config_pool].names.each do |name|
        Dependo::Registry[:crls][name] = R509::CRL::Administrator.new(Dependo::Registry[:config_pool][name])
        Dependo::Registry[:options_builders][name] = R509::CertificateAuthority::OptionsBuilder.new(Dependo::Registry[:config_pool][name])
        Dependo::Registry[:certificate_authorities][name] = R509::CertificateAuthority::Signer.new(Dependo::Registry[:config_pool][name])
      end
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
