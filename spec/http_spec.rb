require File.dirname(__FILE__) + '/spec_helper'
require "openssl"

describe R509::CertificateAuthority::HTTP::Server do
  before :each do
    # clear the dependo before each test
    Dependo::Registry.clear
    Dependo::Registry[:log] = Logger.new(nil)
    R509::CertificateAuthority::HTTP::Config.load_config(File.dirname(__FILE__)+"/fixtures/test_config.yaml")
    Dependo::Registry[:crls] = { "test_ca" => double("crl") }
    Dependo::Registry[:certificate_authorities] = { "test_ca" => double("test_ca") }
    Dependo::Registry[:options_builders] = { "test_ca" => double("options_builder") }
    @subject_parser = double("subject parser")
    #@validity_period_converter = double("validity period converter")
    @csr_factory = double("csr factory")
    @spki_factory = double("spki factory")
  end

  def app
    @app ||= R509::CertificateAuthority::HTTP::Server
    @app.send(:set, :subject_parser, @subject_parser)
    #@app.send(:set, :validity_period_converter, @validity_period_converter)
    @app.send(:set, :csr_factory, @csr_factory)
    @app.send(:set, :spki_factory, @spki_factory)
  end

  context "get CRL" do
    it "gets the CRL" do
      crl = double('crl')
      crl.should_receive(:to_pem).and_return("generated crl")
      Dependo::Registry[:crls]["test_ca"].should_receive(:generate_crl).and_return(crl)
      get "/1/crl/test_ca/get"
      last_response.should be_ok
      last_response.content_type.should match(/text\/plain/)
      last_response.body.should == "generated crl"
    end
    it "when CA is not found" do
      get "/1/crl/bogus/get/"
      last_response.status.should == 500
      last_response.body.should == "#<ArgumentError: CA not found>"
    end
  end

  context "generate CRL" do
    it "generates the CRL" do
      crl = double('crl')
      crl.should_receive(:to_pem).and_return("generated crl")
      Dependo::Registry[:crls]["test_ca"].should_receive(:generate_crl).and_return(crl)
      get "/1/crl/test_ca/generate"
      last_response.should be_ok
      last_response.body.should == "generated crl"
    end
    it "when CA is not found" do
      get "/1/crl/bogus/generate/"
      last_response.status.should == 500
      last_response.body.should == "#<ArgumentError: CA not found>"
    end
  end

  context "issue certificate" do
    it "when no parameters are given" do
      post "/1/certificate/issue"
      last_response.should_not be_ok
      last_response.body.should == "#<ArgumentError: Must provide a CA>"
    end
    it "when there's a profile, subject, CSR, validity period, but no ca" do
      post "/1/certificate/issue", "profile" => "my profile", "subject" => "subject", "csr" => "my csr", "validityPeriod" => 365
      last_response.should_not be_ok
      last_response.body.should == "#<ArgumentError: Must provide a CA>"
    end
    it "when there's a ca, profile, subject, CSR, but no validity period" do
      post "/1/certificate/issue", "ca" => "test_ca", "profile" => "my profile", "subject" => "subject", "csr" => "my csr"
      last_response.should_not be_ok
      last_response.body.should == "#<ArgumentError: Must provide a validity period>"
    end
    it "when there's a ca, profile, subject, validity period, but no CSR" do
      post "/1/certificate/issue", "ca" => "test_ca", "profile" => "my profile", "subject" => "subject", "validityPeriod" => 365
      last_response.should_not be_ok
      last_response.body.should == "#<ArgumentError: Must provide a CSR or SPKI>"
    end
    it "when there's a ca, profile, CSR, validity period, but no subject" do
      @subject_parser.should_receive(:parse).with(anything, "subject").and_return(R509::Subject.new)
      post "/1/certificate/issue", "ca" => "test_ca", "profile" => "profile", "validityPeriod" => 365, "csr" => "csr"
      last_response.should_not be_ok
      last_response.body.should == "#<ArgumentError: Must provide a subject>"
    end
    it "when there's a ca, subject, CSR, validity period, but no profile" do
      post "/1/certificate/issue", "ca" => "test_ca", "subject" => "subject", "validityPeriod" => 365, "csr" => "csr"
      last_response.should_not be_ok
      last_response.body.should == "#<ArgumentError: Must provide a CA profile>"
    end
    it "when the given CA is not found" do
      post "/1/certificate/issue", "ca" => "some bogus CA"
      last_response.should_not be_ok
      last_response.body.should == "#<ArgumentError: CA not found>"
    end
    it "fails to issue" do
      csr = double("csr")
      @csr_factory.should_receive(:build).with({:csr => "csr"}).and_return(csr)
      #@validity_period_converter.should_receive(:convert).with("365").and_return({:not_before => 1, :not_after => 2})
      subject = R509::Subject.new [["CN", "domain.com"]]
      @subject_parser.should_receive(:parse).with(anything, "subject").and_return(subject)
      Dependo::Registry[:options_builders]["test_ca"].should_receive(:build_and_enforce).with(:csr => csr, :profile_name => "profile", :extensions => [], :subject => subject, :message_digest =>nil, :not_before=> kind_of(Time), :not_after => kind_of(Time) ).and_raise(R509::R509Error.new("failed to issue because of: good reason"))

      post "/1/certificate/issue", "ca" => "test_ca", "profile" => "profile", "subject" => "subject", "validityPeriod" => 365, "csr" => "csr"
      last_response.should_not be_ok
      last_response.body.should == "#<R509::R509Error: failed to issue because of: good reason>"
    end
    it "issues a CSR with no SAN extensions" do
      csr = double("csr")
      @csr_factory.should_receive(:build).with(:csr => "csr").and_return(csr)
      #@validity_period_converter.should_receive(:convert).with("365").and_return({:not_before => 1, :not_after => 2})
      subject = R509::Subject.new [["CN", "domain.com"]]
      @subject_parser.should_receive(:parse).with(anything, "subject").and_return(subject)
      cert = double("cert")
      Dependo::Registry[:options_builders]["test_ca"].should_receive(:build_and_enforce).with(:csr => csr, :profile_name => "profile", :extensions => [], :subject => subject, :message_digest =>nil, :not_before=> kind_of(Time), :not_after => kind_of(Time) ).and_return(:csr => csr, :profile_name => "profile", :subject => subject, :message_digest => "SHA1", :not_before=> kind_of(Time), :not_after => kind_of(Time) )
      Dependo::Registry[:certificate_authorities]["test_ca"].should_receive(:sign).and_return(cert)
      cert.should_receive(:to_pem).and_return("signed cert")

      post "/1/certificate/issue", "ca" => "test_ca", "profile" => "profile", "subject" => "subject", "validityPeriod" => 365, "csr" => "csr"
      last_response.should be_ok
      last_response.body.should == "signed cert"
    end
    it "issues a CSR with SAN extensions" do
      csr = double("csr")
      @csr_factory.should_receive(:build).with(:csr => "csr").and_return(csr)
      #@validity_period_converter.should_receive(:convert).with("365").and_return({:not_before => 1, :not_after => 2})
      subject = R509::Subject.new [["CN", "domain.com"]]
      @subject_parser.should_receive(:parse).with(anything, "subject").and_return(subject)
      cert = double("cert")
      Dependo::Registry[:options_builders]["test_ca"].should_receive(:build_and_enforce).with(:csr => csr, :profile_name => "profile", :extensions => kind_of(Array), :subject => subject, :extensions => kind_of(Array), :message_digest =>nil, :not_before=> kind_of(Time), :not_after => kind_of(Time) ).and_return(:csr => csr, :profile_name => "profile", :subject => subject, :message_digest => "SHA1", :not_before=> kind_of(Time), :not_after => kind_of(Time) )
      Dependo::Registry[:certificate_authorities]["test_ca"].should_receive(:sign).and_return(cert)
      cert.should_receive(:to_pem).and_return("signed cert")

      post "/1/certificate/issue", "ca" => "test_ca", "profile" => "profile", "subject" => "subject", "validityPeriod" => 365, "csr" => "csr", "extensions[subjectAlternativeName][]" => ["domain1.com","domain2.com"]
      last_response.should be_ok
      last_response.body.should == "signed cert"
    end
    it "issues a CSR with dNSNames" do
      csr = double("csr")
      @csr_factory.should_receive(:build).with(:csr => "csr").and_return(csr)
      #@validity_period_converter.should_receive(:convert).with("365").and_return({:not_before => 1, :not_after => 2})
      subject = R509::Subject.new [["CN", "domain.com"]]
      @subject_parser.should_receive(:parse).with(anything, "subject").and_return(subject)
      cert = double("cert")
      Dependo::Registry[:options_builders]["test_ca"].should_receive(:build_and_enforce).with(:csr => csr, :profile_name => "profile", :subject => subject, :extensions => kind_of(Array), :message_digest =>nil, :not_before=> kind_of(Time), :not_after => kind_of(Time) ).and_return(:csr => csr, :profile_name => "profile", :subject => subject, :message_digest => "SHA1")
      Dependo::Registry[:certificate_authorities]["test_ca"].should_receive(:sign).and_return(cert)
      cert.should_receive(:to_pem).and_return("signed cert")

      post "/1/certificate/issue", "ca" => "test_ca", "profile" => "profile", "subject" => "subject", "validityPeriod" => 365, "csr" => "csr", "extensions[dNSNames][]" => ["domain1.com","domain2.com"]
      last_response.should be_ok
      last_response.body.should == "signed cert"
    end
    it "issues a CSR with both SAN names and dNSNames provided (and ignore the dNSNames)" do
      csr = double("csr")
      @csr_factory.should_receive(:build).with(:csr => "csr").and_return(csr)
      #@validity_period_converter.should_receive(:convert).with("365").and_return({:not_before => 1, :not_after => 2})
      subject = R509::Subject.new [["CN", "domain.com"]]
      @subject_parser.should_receive(:parse).with(anything, "subject").and_return(subject)
      cert = double("cert")
      Dependo::Registry[:options_builders]["test_ca"].should_receive(:build_and_enforce).with(:csr => csr, :profile_name => "profile", :subject => subject, :extensions => kind_of(Array), :message_digest => nil, :not_before=> kind_of(Time), :not_after => kind_of(Time) ).and_return(:csr => csr)
      Dependo::Registry[:certificate_authorities]["test_ca"].should_receive(:sign).and_return(cert)
      cert.should_receive(:to_pem).and_return("signed cert")

      post "/1/certificate/issue", "ca" => "test_ca", "profile" => "profile", "subject" => "subject", "validityPeriod" => 365, "csr" => "csr", "extensions[subjectAlternativeName][]" => ["domain1.com","domain2.com"], "extensions[dNSNames][]" => ["domain3.com", "domain4.com"]
      last_response.should be_ok
      last_response.body.should == "signed cert"
    end
    it "issues an SPKI without SAN extensions" do
      #@validity_period_converter.should_receive(:convert).with("365").and_return({:not_before => 1, :not_after => 2})
      subject = R509::Subject.new [["CN", "domain.com"]]
      @subject_parser.should_receive(:parse).with(anything, "subject").and_return(subject)
      spki = double("spki")
      @spki_factory.should_receive(:build).with(:spki => "spki", :subject => subject).and_return(spki)
      cert = double("cert")
      Dependo::Registry[:options_builders]["test_ca"].should_receive(:build_and_enforce).with(:spki => spki, :profile_name => "profile", :extensions => [], :subject => subject, :message_digest => nil, :not_before=> kind_of(Time), :not_after => kind_of(Time) ).and_return(:spki => spki, :not_before=> kind_of(Time), :not_after => kind_of(Time) )
      Dependo::Registry[:certificate_authorities]["test_ca"].should_receive(:sign).and_return(cert)
      cert.should_receive(:to_pem).and_return("signed cert")

      post "/1/certificate/issue", "ca" => "test_ca", "profile" => "profile", "subject" => "subject", "validityPeriod" => 365, "spki" => "spki"
      last_response.should be_ok
      last_response.body.should == "signed cert"
    end
    it "issues an SPKI with SAN extensions" do
      #@validity_period_converter.should_receive(:convert).with("365").and_return({:not_before => 1, :not_after => 2})
      subject = R509::Subject.new [["CN", "domain.com"]]
      @subject_parser.should_receive(:parse).with(anything, "subject").and_return(subject)
      spki = double("spki")
      @spki_factory.should_receive(:build).with(:spki => "spki", :subject => subject).and_return(spki)
      cert = double("cert")
      Dependo::Registry[:options_builders]["test_ca"].should_receive(:build_and_enforce).with(:spki => spki, :profile_name => "profile", :extensions => kind_of(Array), :subject => subject, :message_digest => nil, :not_before=> kind_of(Time), :not_after => kind_of(Time) ).and_return(:spki => spki, :not_before=> kind_of(Time), :not_after => kind_of(Time) )
      Dependo::Registry[:certificate_authorities]["test_ca"].should_receive(:sign).and_return(cert)
      cert.should_receive(:to_pem).and_return("signed cert")

      post "/1/certificate/issue", "ca" => "test_ca", "profile" => "profile", "subject" => "subject", "validityPeriod" => 365, "spki" => "spki", "extensions[subjectAlternativeName][]" => ["domain1.com","domain2.com"]
      last_response.should be_ok
      last_response.body.should == "signed cert"
    end
    it "when there are empty SAN names" do
      csr = double("csr")
      @csr_factory.should_receive(:build).with(:csr => "csr").and_return(csr)
      #@validity_period_converter.should_receive(:convert).with("365").and_return({:not_before => 1, :not_after => 2})
      subject = R509::Subject.new [["CN", "domain.com"]]
      @subject_parser.should_receive(:parse).with(anything, "subject").and_return(subject)
      cert = double("cert")
      Dependo::Registry[:options_builders]["test_ca"].should_receive(:build_and_enforce).with(:csr => csr, :profile_name => "profile", :subject => subject, :extensions => kind_of(Array), :message_digest => nil, :not_before=> kind_of(Time), :not_after => kind_of(Time) ).and_return(:csr => csr, :not_before=> kind_of(Time), :not_after => kind_of(Time) )
      Dependo::Registry[:certificate_authorities]["test_ca"].should_receive(:sign).and_return(cert)
      cert.should_receive(:to_pem).and_return("signed cert")

      post "/1/certificate/issue", "ca" => "test_ca", "profile" => "profile", "subject" => "subject", "validityPeriod" => 365, "csr" => "csr", "extensions[subjectAlternativeName][]" => ["domain1.com","domain2.com","",""]
      last_response.should be_ok
      last_response.body.should == "signed cert"
    end
  end

  context "revoke certificate" do
    it "when no CA is given" do
      post "/1/certificate/revoke", "serial" => "foo"
      last_response.status.should == 500
      last_response.body.should == "#<ArgumentError: CA must be provided>"
    end
    it "when CA is not found" do
      post "/1/certificate/revoke", "ca" => "bogus ca name", "serial" => "foo"
      last_response.status.should == 500
      last_response.body.should == "#<ArgumentError: CA not found>"
    end
    it "when no serial is given" do
      post "/1/certificate/revoke", "ca" => "test_ca"
      last_response.should_not be_ok
      last_response.body.should == "#<ArgumentError: Serial must be provided>"
    end
    it "when serial is given but not reason" do
      Dependo::Registry[:crls]["test_ca"].should_receive(:revoke_cert).with("12345", nil).and_return(nil)
      crl_obj = double("crl-obj")
      Dependo::Registry[:crls]["test_ca"].should_receive(:generate_crl).and_return(crl_obj)
      crl_obj.should_receive(:to_pem).and_return("generated crl")
      post "/1/certificate/revoke", "ca" => "test_ca", "serial" => "12345"
      last_response.should be_ok
      last_response.body.should == "generated crl"
    end
    it "when serial and reason are given" do
      Dependo::Registry[:crls]["test_ca"].should_receive(:revoke_cert).with("12345", 1).and_return(nil)
      crl_obj = double("crl-obj")
      Dependo::Registry[:crls]["test_ca"].should_receive(:generate_crl).and_return(crl_obj)
      crl_obj.should_receive(:to_pem).and_return("generated crl")
      post "/1/certificate/revoke", "ca" => "test_ca", "serial" => "12345", "reason" => "1"
      last_response.should be_ok
      last_response.body.should == "generated crl"
    end
    it "when serial is not an integer" do
      Dependo::Registry[:crls]["test_ca"].should_receive(:revoke_cert).with("foo", nil).and_raise(R509::R509Error.new("some r509 error"))
      post "/1/certificate/revoke", "ca" => "test_ca", "serial" => "foo"
      last_response.should_not be_ok
      last_response.body.should == "#<R509::R509Error: some r509 error>"
    end
    it "when reason is not an integer" do
      Dependo::Registry[:crls]["test_ca"].should_receive(:revoke_cert).with("12345", 0).and_return(nil)
      crl_obj = double("crl-obj")
      Dependo::Registry[:crls]["test_ca"].should_receive(:generate_crl).and_return(crl_obj)
      crl_obj.should_receive(:to_pem).and_return("generated crl")
      post "/1/certificate/revoke", "ca" => "test_ca", "serial" => "12345", "reason" => "foo"
      last_response.should be_ok
      last_response.body.should == "generated crl"
    end
    it "when reason is an empty string" do
      Dependo::Registry[:crls]["test_ca"].should_receive(:revoke_cert).with("12345", nil).and_return(nil)
      crl_obj = double("crl-obj")
      Dependo::Registry[:crls]["test_ca"].should_receive(:generate_crl).and_return(crl_obj)
      crl_obj.should_receive(:to_pem).and_return("generated crl")
      post "/1/certificate/revoke", "ca" => "test_ca", "serial" => "12345", "reason" => ""
      last_response.should be_ok
      last_response.body.should == "generated crl"
    end
  end

  context "unrevoke certificate" do
    it "when no CA is given" do
      post "/1/certificate/unrevoke", "serial" => "foo"
      last_response.status.should == 500
      last_response.body.should == "#<ArgumentError: CA must be provided>"
    end
    it "when CA is not found" do
      post "/1/certificate/unrevoke", "ca" => "bogus ca", "serial" => "foo"
      last_response.status.should == 500
      last_response.body.should == "#<ArgumentError: CA not found>"
    end
    it "when no serial is given" do
      post "/1/certificate/unrevoke", "ca" => "test_ca"
      last_response.should_not be_ok
      last_response.body.should == "#<ArgumentError: Serial must be provided>"
    end
    it "when serial is given" do
      Dependo::Registry[:crls]["test_ca"].should_receive(:unrevoke_cert).with(12345).and_return(nil)
      crl_obj = double("crl-obj")
      Dependo::Registry[:crls]["test_ca"].should_receive(:generate_crl).and_return(crl_obj)
      crl_obj.should_receive(:to_pem).and_return("generated crl")
      post "/1/certificate/unrevoke", "ca" => "test_ca", "serial" => "12345"
      last_response.should be_ok
      last_response.body.should == "generated crl"
    end
  end

end
