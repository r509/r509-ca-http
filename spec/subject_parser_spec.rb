require File.dirname(__FILE__) + '/spec_helper'

describe R509::CertificateAuthority::Http::SubjectParser do
    before :all do
        @parser = R509::CertificateAuthority::Http::SubjectParser.new
    end

    it "when the query string is nil" do
        expect { @parser.parse(nil) }.to raise_error(ArgumentError, "Must provide a query string")
    end
    it "when the query string is empty" do
        subject = @parser.parse("")
        subject.empty?.should == true
    end
    it "when the query string doesn't contain any subject data" do
        subject = @parser.parse("validityPeriod=1095&data=blahblah")
        subject.empty?.should == true
    end
    it "when there is one subject component" do
        subject = @parser.parse("validityPeriod=1095&subject[CN]=domain.com&data=blahblah")
        subject.empty?.should == false
        subject["CN"].should == "domain.com"
    end
    it "when there are three subject components should maintain order" do
        subject = @parser.parse("validityPeriod=1095&subject[CN]=domain.com&subject[O]=org&subject[L]=locality&data=blahblah")
        subject.empty?.should == false
        subject["CN"].should == "domain.com"
        subject["O"].should == "org"
        subject["L"].should == "locality"
        subject.to_s.should == "/CN=domain.com/O=org/L=locality"
    end
    it "when one of the subject components has an unknown key" do
        expect { subject = @parser.parse("validityPeriod=1095&subject[CN]=domain.com&subject[NOTATHING]=org&subject[L]=locality&data=blahblah") }.to raise_error(OpenSSL::X509::NameError)
    end
    it "when one of the subject components is just an OID" do
        subject = @parser.parse("validityPeriod=1095&subject[CN]=domain.com&subject[1.3.6.1.4.1.311.60.2.1.3]=org&subject[L]=locality&data=blahblah")
        subject.empty?.should == false
        subject["CN"].should == "domain.com"
        subject["1.3.6.1.4.1.311.60.2.1.3"].should == "org"
        subject["L"].should == "locality"
        subject.to_s.should == "/CN=domain.com/1.3.6.1.4.1.311.60.2.1.3=org/L=locality"
    end
    it "when one of the subject components is an empty string" do
        subject = @parser.parse("validityPeriod=1095&subject[CN]=domain.com&subject[O]=&subject[L]=locality&data=blahblah")
        subject.empty?.should == false
        subject["CN"].should == "domain.com"
        subject["O"].should == nil
        subject["L"].should == "locality"
        subject.to_s.should == "/CN=domain.com/L=locality"
    end
end
