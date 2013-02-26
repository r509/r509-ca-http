module R509::CertificateAuthority::HTTP
  class ValidityPeriodConverter
    def convert(validity_period)
      if validity_period.nil?
        raise ArgumentError, "Must provide validity period"
      end
      if validity_period.to_i <= 0
        raise ArgumentError, "Validity period must be positive"
      end
      {
        :not_before => Time.now - 6 * 60 * 60,
        :not_after => Time.now + validity_period.to_i,
      }
    end
  end
end
