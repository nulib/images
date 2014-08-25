require 'spec_helper'

describe MultiresimageHelper do

  context "vra validation" do
    describe "with invalid vra" do
      it "should fail" do
        expect{ MultiresimageHelper.validate_vra( File.open("#{ Rails.root }/spec/fixtures/vra_image_minimal.xml").read )}.to raise_error
      end
    end
  end

end