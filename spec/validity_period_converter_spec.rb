require File.dirname(__FILE__) + "/spec_helper"

describe R509::CertificateAuthority::Http::ValidityPeriodConverter do
    before :all do
        @converter = R509::CertificateAuthority::Http::ValidityPeriodConverter.new
    end

    it "when validity period is nil" do
        expect { @converter.convert(nil) }.to raise_error(ArgumentError, "Must provide validity period")
    end
    it "when validity period is integer, negative" do
        expect { @converter.convert(-1) }.to raise_error(ArgumentError, "Validity period must be positive")
    end
    it "when validity period is string, negative" do
        expect { @converter.convert("-1") }.to raise_error(ArgumentError, "Validity period must be positive")
    end
    it "when validity period is integer, zero" do
        expect { @converter.convert(0) }.to raise_error(ArgumentError, "Validity period must be positive")
    end
    it "when validity period is string, zero" do
        expect { @converter.convert("0") }.to raise_error(ArgumentError, "Validity period must be positive")
    end
    it "when validity period is integer, 1" do
        not_before = Time.now - 6*60*60
        not_after = Time.now + 1*24*60*60
        period = @converter.convert(1)
        period[:not_before].to_i.should == not_before.to_i
        period[:not_after].to_i.should == not_after.to_i
    end
    it "when validity period is string, 1" do
        not_before = Time.now - 6*60*60
        not_after = Time.now + 1*24*60*60
        period = @converter.convert("1")
        period[:not_before].to_i.should == not_before.to_i
        period[:not_after].to_i.should == not_after.to_i
    end
    it "when validity period is integer, 365" do
        not_before = Time.now - 6*60*60
        not_after = Time.now + 365*24*60*60
        period = @converter.convert(365)
        period[:not_before].to_i.should == not_before.to_i
        period[:not_after].to_i.should == not_after.to_i
    end
    it "when validity period is string, 365" do
        not_before = Time.now - 6*60*60
        not_after = Time.now + 365*24*60*60
        period = @converter.convert("365")
        period[:not_before].to_i.should == not_before.to_i
        period[:not_after].to_i.should == not_after.to_i
    end
    it "when validity period is integer, 730" do
        not_before = Time.now - 6*60*60
        not_after = Time.now + 730*24*60*60
        period = @converter.convert(730)
        period[:not_before].to_i.should == not_before.to_i
        period[:not_after].to_i.should == not_after.to_i
    end
    it "when validity period is string, 730" do
        not_before = Time.now - 6*60*60
        not_after = Time.now + 730*24*60*60
        period = @converter.convert("730")
        period[:not_before].to_i.should == not_before.to_i
        period[:not_after].to_i.should == not_after.to_i
    end
    it "when validity period is integer, 1095" do
        not_before = Time.now - 6*60*60
        not_after = Time.now + 1095*24*60*60
        period = @converter.convert(1095)
        period[:not_before].to_i.should == not_before.to_i
        period[:not_after].to_i.should == not_after.to_i
    end
    it "when validity period is string, 1095" do
        not_before = Time.now - 6*60*60
        not_after = Time.now + 1095*24*60*60
        period = @converter.convert("1095")
        period[:not_before].to_i.should == not_before.to_i
        period[:not_after].to_i.should == not_after.to_i
    end
end
