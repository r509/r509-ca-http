module R509::CertificateAuthority::HTTP
  module Factory
    class CSRFactory
      def build(options)
        R509::CSR.new(options)
      end
    end

    class SPKIFactory
      def build(options)
        R509::SPKI.new(options)
      end
    end
  end
end
