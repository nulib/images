require 'spec_helper'

describe MultiresimageHelper do

  context "vra validation" do
    describe "with invalid vra" do
      it "should fail" do
        expect{ MultiresimageHelper.validate_vra( File.open("#{ Rails.root }/spec/fixtures/vra_image_minimal.xml").read )}.to raise_error
      end
    end

    describe "with valid vra" do
      it "should pass" do
        expect{ MultiresimageHelper.validate_vra( "<vra:vra></vra:vra>" )}.to be_true
      end
    end
  end

end