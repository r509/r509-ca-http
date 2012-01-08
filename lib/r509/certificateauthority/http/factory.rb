module R509::CertificateAuthority::Http
    module Factory
        class CsrFactory
            def build(options)
                R509::Csr.new(options)
            end
        end

        class SpkiFactory
            def build(options)
                R509::Spki.new(options)
            end
        end
    end
end
