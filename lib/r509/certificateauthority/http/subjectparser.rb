module R509
  module CertificateAuthority
    module HTTP
      class SubjectParser
        def parse(raw, name="subject")
          if raw.nil?
            raise ArgumentError, "Must provide a query string"
          end

          subject = R509::Subject.new
          raw.split(/[&;] */n).each { |pair|
            key, value = pair.split('=', 2).map { |data| unescape(data) }
            match = key.match(/#{name}\[(.*)\]/)
            if not match.nil? and not value.empty?
              subject[match[1]] = value
            end
          }
          subject
        end

        if defined?(::Encoding)
          def unescape(s, encoding = Encoding::UTF_8)
            URI.decode_www_form_component(s, encoding)
          end
        else
          def unescape(s, encoding = nil)
            URI.decode_www_form_component(s, encoding)
          end
        end
      end
    end
  end
end
