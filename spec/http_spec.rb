require File.dirname(__FILE__) + '/spec_helper'
require "openssl"


describe R509::CertificateAuthority::Http::Server do
    before :each do
        @crl = double("crl")
        @ca = double("ca")
    end

    def app
        @app ||= R509::CertificateAuthority::Http::Server
        @app.send(:set, :crl, @crl)
        @app.send(:set, :ca, @ca)
    end

    context "get CRL" do
        it "gets the CRL" do
            @crl.should_receive(:to_pem).and_return("generated crl")
            get "/1/crl/get"
            last_response.should be_ok
            last_response.body.should == "generated crl"
        end
    end

    context "generate CRL" do
        it "generates the CRL" do
            @crl.should_receive(:generate_crl).and_return("generated crl")
            get "/1/crl/generate"
            last_response.should be_ok
            last_response.body.should == "generated crl"
        end
    end

    context "issue certificate" do
        it "when no parameters are given"
        it "when a subject line should be in order" do
            post "/1/certificate/issue", "sub[]" => [{"key" => "cn", "value" => "common name"}, {"key" => "o", "value" => "org"}, {"key" => "l", "value" => "locality"}]
        end
    end

    context "revoke certificate" do
        it "when no serial is given" do
            post "/1/certificate/revoke"
            last_response.should_not be_ok
            last_response.body.should == "Serial must be provided"
        end
        it "when serial is given but not reason" do
            @crl.should_receive(:revoke_cert).with(12345, 0).and_return(nil)
            @crl.should_receive(:to_pem).and_return("generated crl")
            post "/1/certificate/revoke", "serial" => "12345"
            last_response.should be_ok
            last_response.body.should == "generated crl"
        end
        it "when serial and reason are given" do
            @crl.should_receive(:revoke_cert).with(12345, 1).and_return(nil)
            @crl.should_receive(:to_pem).and_return("generated crl")
            post "/1/certificate/revoke", "serial" => "12345", "reason" => "1"
            last_response.should be_ok
            last_response.body.should == "generated crl"
        end
        it "when serial is not an integer" do
            @crl.should_receive(:revoke_cert).with(0, 0).and_raise(R509::R509Error.new("some r509 error"))
            post "/1/certificate/revoke", "serial" => "foo"
            last_response.should_not be_ok
            last_response.body.should == "some r509 error"
        end
        it "when reason is not an integer" do
            @crl.should_receive(:revoke_cert).with(12345, 0).and_return(nil)
            @crl.should_receive(:to_pem).and_return("generated crl")
            post "/1/certificate/revoke", "serial" => "12345", "reason" => "foo"
            last_response.should be_ok
            last_response.body.should == "generated crl"
        end
    end

    context "unrevoke certificate" do
        it "when no serial is given" do
            post "/1/certificate/unrevoke"
            last_response.should_not be_ok
            last_response.body.should == "Serial must be provided"
        end
        it "when serial is given" do
            @crl.should_receive(:unrevoke_cert).with(12345).and_return(nil)
            @crl.should_receive(:to_pem).and_return("generated crl")
            post "/1/certificate/unrevoke", "serial" => "12345"
            last_response.should be_ok
            last_response.body.should == "generated crl"
        end
    end

end
