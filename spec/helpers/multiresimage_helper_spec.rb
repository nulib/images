require 'rails_helper'
require 'multiresimage_helper'

describe MultiresimageHelper, :type => :helper do

  context "vra validation" do
    describe "with invalid vra" do
      it "should fail" do
        expect( MultiresimageHelper.valid_vra?( File.open("#{ Rails.root }/spec/fixtures/vra_image_minimal_invalid.xml").read )).to be_falsey
      end
    end

    describe "with valid vra" do
      it "should pass" do
        expect( MultiresimageHelper.validate_vra( File.open("#{ Rails.root }/spec/fixtures/vra_image_minimal.xml").read )).to be_truthy
      end
    end
  end

end