require File.dirname(__FILE__) + '/spec_helper'

describe R509::CertificateAuthority::Http do
    def app
        @app ||= R509::CertificateAuthority::Http
    end

    context "get CRL" do
        it "gets the CRL" do
            get "/1/crl/get"
            last_response.should be_ok
        end
    end

    context "generate CRL" do
        it "generates the CRL" do
            get "/1/crl/generate"
            last_response.should be_ok
        end
    end

    context "issue certificate" do
        it "when no parameters are given"
    end

    context "revoke certificate" do
        it "when no serial is given"
    end

end
